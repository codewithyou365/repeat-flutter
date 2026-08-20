import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:repeat_flutter/common/foreground_service.dart';
import 'package:repeat_flutter/common/screen_brightness_helper.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
import 'package:repeat_flutter/logic/ai/ai_model_help.dart';
import 'package:repeat_flutter/logic/ai/ai_model_paths.dart';
import 'package:repeat_flutter/logic/ai/record_session.dart';
import 'package:repeat_flutter/logic/ai/vad_isolate.dart';
import 'package:repeat_flutter/logic/ai/wav.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'sc_cr_material_record_state.dart';

class ScCrMaterialRecordLogic extends GetxController {
  static const String id = "ScCrMaterialRecordLogic";
  final ScCrMaterialRecordState state = ScCrMaterialRecordState();

  final AudioRecorder _recorder = AudioRecorder();
  VadIsolate? _vad;
  StreamSubscription<Uint8List>? _audioSub;
  StreamSubscription<VadSegment>? _segSub;
  Timer? _ticker;
  int _startedAtMs = 0;

  /// 播放反馈音期间到达的 PCM 一律丢弃，免得把自己放出去的声音当成用户在说话。
  /// 平台 AEC（voiceCommunication）大多数机器上够用，但有些机器的 AEC 是摆设，
  /// 这个硬闸是兜底，十几行而已。
  int _muteUntilMs = 0;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is List && args.isNotEmpty && args.first is Book) {
      state.book = args.first as Book;
    }
  }

  @override
  void onClose() {
    // 页面无论怎么退出（返回键、异常、被替换）都要把外设关干净：
    // 麦克风、前台服务、常亮、屏幕亮度，漏一个都是用户能直接看到的故障。
    _teardown();
    super.onClose();
  }

  Future<void> start() async {
    if (state.recording.value || state.starting.value) {
      return;
    }
    state.starting.value = true;
    state.error.value = '';
    try {
      // ---- 1. 先拿麦克风权限。
      // Android 14+ 没有 RECORD_AUDIO 就去起 microphone 型前台服务会直接抛 SecurityException，
      // 所以这一步必须在起前台服务之前。
      if (!await _ensureMicPermission()) {
        state.error.value = I18nKey.aiRecordNoMicPermission.tr;
        return;
      }

      // ---- 2. 起前台服务，**必须在页面还可见的时候起**。
      // Android 11+ 的 while-in-use 规则会把后台启动的麦克风前台服务静默静音——
      // 不抛异常，只是从此录到的全是零。所以顺序是死的：权限 → 前台服务 → startStream。
      await ForegroundService.start(kind: ForegroundKind.record);

      // ---- 3. 音频会话：录放同时进行，且不要独占音频焦点，否则会跟自己的录音器打架。
      await _configureAudioSession();

      // ---- 4. 起 VAD isolate（模型加载几百毫秒，要在开录之前完成，
      //         否则最开始那几百毫秒的音频会堆在流里）。
      if (!await _startVad()) {
        return;
      }

      // ---- 5. 最后才真正开录。
      state.session = await RecordSession.create(state.book.id!);
      state.segments.clear();
      final stream = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: Wav.sampleRate,
        numChannels: Wav.numChannels,
        // voiceCommunication 走平台的 AEC/AGC/NS 管线，是回声问题真正的解法，
        // 顺带还会把采样率钳到 16k 单声道——正好是模型要的。
        androidConfig: AndroidRecordConfig(audioSource: AndroidAudioSource.voiceCommunication),
        echoCancel: true,
        noiseSuppress: true,
        // autoGain 会压掉安静段的动态范围，反而让 VAD 更难判停，关掉。
        autoGain: false,
      ));
      _audioSub = stream.listen(_onAudio, onError: (Object e) {
        state.error.value = '$e';
      });

      _startedAtMs = DateTime.now().millisecondsSinceEpoch;
      _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
        state.elapsedMs.value = DateTime.now().millisecondsSinceEpoch - _startedAtMs;
      });
      state.recording.value = true;

      if (state.screenMode.value == RecordScreenMode.black) {
        await enterBlackScreen();
      }
    } catch (e) {
      debugPrint('record start failed: $e');
      state.error.value = '$e';
      await _teardown();
    } finally {
      state.starting.value = false;
    }
  }

  Future<bool> _ensureMicPermission() async {
    try {
      if (await Permission.microphone.isGranted) {
        return true;
      }
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('mic permission failed: $e');
      return false;
    }
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        // defaultToSpeaker：不接耳机时从扬声器出声，否则 playAndRecord 默认走听筒，
        // 用户会以为反馈音没响。mixWithOthers：不掐掉别人正在放的音频。
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker |
            AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        // 不要独占焦点：抢焦点会跟自己的录音器打架，也会把用户的音乐掐了。
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ));
      await session.setActive(true);
    } catch (e) {
      // 配不上不是致命的，录音多半照样能跑，只是回声/路由可能不理想。
      debugPrint('audio session configure failed: $e');
    }
  }

  Future<bool> _startVad() async {
    try {
      final catalog = await AiCatalog.load();
      final entry = await AiModelHelp.selectedFor(AiRole.vad, catalog);
      if (entry == null) {
        state.error.value = I18nKey.aiModelMissing.trArgs([AiRole.vad.label]);
        return false;
      }
      final cfg = AiModelPaths.resolve(entry.cfg, await AiModelHelp.dirOf(entry.id));
      _vad = await VadIsolate.start(cfg);
      _segSub = _vad!.segments.listen(_onSegment, onError: (Object e) {
        state.error.value = '$e';
      });
      return true;
    } catch (e) {
      debugPrint('vad start failed: $e');
      state.error.value = '$e';
      return false;
    }
  }

  void _onAudio(Uint8List bytes) {
    if (DateTime.now().millisecondsSinceEpoch < _muteUntilMs) {
      return;
    }
    _vad?.accept(Wav.pcm16ToFloat32(bytes));
  }

  Future<void> _onSegment(VadSegment seg) async {
    final session = state.session;
    if (session == null) {
      return;
    }
    // 切出一段就立刻给一下震动。息屏时用户看不到屏幕，这是唯一的确认，
    // 而且它零声学足迹，不会像提示音那样灌回麦克风。
    unawaited(HapticFeedback.mediumImpact());
    try {
      // **先落盘再入队推理**：音频是这条流水线上唯一不可再生的产物。
      // 落完盘就算马上被系统杀掉，回来也只丢识别结果，录音一段不丢。
      final record = await session.addSegment(seg.samples);
      state.segments.add(record);
      state.segments.refresh();
    } catch (e) {
      debugPrint('save segment failed: $e');
      state.error.value = '$e';
    }
  }

  /// 播反馈音/译文前后调用，把这段时间的输入闸掉。
  void muteFor(int ms) {
    _muteUntilMs = DateTime.now().millisecondsSinceEpoch + ms + 250;
    // 闸门期间 VAD 收不到数据，内部状态会以为一直是静音；解闸时重置一下，
    // 免得它把闸门前后的语音接成一段。
    _vad?.reset();
  }

  Future<void> enterBlackScreen() async {
    state.blacked.value = true;
    await WakelockPlus.enable();
    await ScreenBrightnessHelper.dim();
  }

  Future<void> exitBlackScreen() async {
    state.blacked.value = false;
    await ScreenBrightnessHelper.restore();
  }

  void toggleScreenMode(RecordScreenMode mode) {
    state.screenMode.value = mode;
  }

  /// 停止录音。会先 flush 一次 VAD，把最后那段还没等到静音的语音也吐出来，
  /// 否则用户说的最后一句会被吞掉。
  Future<void> stop() async {
    if (!state.recording.value) {
      return;
    }
    state.recording.value = false;
    _ticker?.cancel();
    _ticker = null;

    await _audioSub?.cancel();
    _audioSub = null;
    try {
      await _recorder.stop();
    } catch (e) {
      debugPrint('recorder stop failed: $e');
    }

    _vad?.flush();
    // flush 是异步投递的，等一小会儿让最后那段从 isolate 回来并落盘
    await Future<void>.delayed(const Duration(milliseconds: 400));

    await exitBlackScreen();
    await _teardown(keepSession: true);

    final session = state.session;
    if (session == null || session.segments.isEmpty) {
      await session?.discard();
      Snackbar.show(I18nKey.aiRecordNothing.tr);
      Get.back();
      return;
    }
    session.state = RecordSessionState.reviewing;
    await session.save();
    // TODO(Phase 4): 换成 Nav.scCrMaterialRecordReview.push(arguments: [state.book, session.dir])
    Snackbar.show(I18nKey.aiRecordSegments.trArgs(['${session.segments.length}']));
  }

  Future<void> _teardown({bool keepSession = false}) async {
    await _audioSub?.cancel();
    _audioSub = null;
    await _segSub?.cancel();
    _segSub = null;
    _ticker?.cancel();
    _ticker = null;
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (e) {
      debugPrint('teardown recorder failed: $e');
    }
    await _vad?.dispose();
    _vad = null;
    await ForegroundService.stop(kind: ForegroundKind.record);
    await ScreenBrightnessHelper.restore();
    await WakelockPlus.disable();
    try {
      await (await AudioSession.instance).setActive(false);
    } catch (e) {
      debugPrint('audio session deactivate failed: $e');
    }
    if (!keepSession) {
      state.session = null;
    }
    state.recording.value = false;
    state.blacked.value = false;
  }

  /// 只有 Android 需要前台服务才能真息屏；桌面端不存在这个问题，iOS 靠 audio 后台模式。
  bool get trueScreenOffSupported => !kIsWeb && Platform.isAndroid;
}
