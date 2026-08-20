import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:repeat_flutter/common/foreground_service.dart';
import 'package:repeat_flutter/common/screen_brightness_helper.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
import 'package:repeat_flutter/logic/ai/ai_lang.dart';
import 'package:repeat_flutter/logic/ai/ai_model_help.dart';
import 'package:repeat_flutter/logic/ai/ai_model_paths.dart';
import 'package:repeat_flutter/logic/ai/ai_model_switch.dart';
import 'package:repeat_flutter/logic/ai/ai_pipeline.dart';
import 'package:repeat_flutter/logic/ai/infer_isolate.dart';
import 'package:repeat_flutter/logic/ai/record_session.dart';
import 'package:repeat_flutter/logic/ai/vad_isolate.dart';
import 'package:repeat_flutter/logic/ai/wav.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'sc_cr_material_record_state.dart';

class ScCrMaterialRecordLogic extends GetxController {
  static const String id = "ScCrMaterialRecordLogic";
  final ScCrMaterialRecordState state = ScCrMaterialRecordState();

  final AudioRecorder _recorder = AudioRecorder();
  VadIsolate? _vad;
  InferIsolate? _infer;
  StreamSubscription<Uint8List>? _audioSub;
  StreamSubscription<VadSegment>? _segSub;
  StreamSubscription<InferResult>? _inferSub;

  /// 专门放译文的播放器。跟提示音分开，且常驻不 dispose——
  /// 每次 new 一个 AudioPlayer 都要几百毫秒，跟不上出段的节奏。
  final AudioPlayer _ttsPlayer = AudioPlayer();
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
    loadModels();
    // 必须等第一帧之后：onInit 阶段 Get.context 还是 null，MsgBox 会静默不弹。
    WidgetsBinding.instance.addPostFrameCallback((_) => checkUnfinished());
  }

  @override
  void onClose() {
    // 页面无论怎么退出（返回键、异常、被替换）都要把外设关干净：
    // 麦克风、前台服务、常亮、屏幕亮度，漏一个都是用户能直接看到的故障。
    _teardown();
    _ttsPlayer.dispose();
    super.onClose();
  }

  /// 读一遍四个角色当前生效的模型，给控制区显示用。
  Future<void> loadModels() async {
    try {
      final catalog = await AiCatalog.load();
      final selected = await AiModelSwitch.current(catalog);
      for (final role in AiRole.values) {
        state.modelNames[role] = selected[role]?.name ?? '';
      }
      state.asrLanguage.value = await AiLang.current();
      final (sid, voices) = await AiModelSwitch.voice(catalog);
      state.ttsVoice.value = sid;
      state.ttsVoices.value = voices;
    } catch (e) {
      debugPrint('loadModels failed: $e');
    }
  }

  /// 换某个角色的模型。
  ///
  /// 录着的时候不给换：模型早在 [start] 里就加载进 isolate 了，这时候改选中项
  /// 界面上像是换了、实际这一趟还是老模型。停下来再换，下一趟才作数。
  Future<void> pickModel(AiRole role) async {
    if (state.recording.value || state.starting.value) {
      return;
    }
    if (await AiModelSwitch.pick(role)) {
      await loadModels();
    }
  }

  /// 钉死识别语言。多语种模型判错语种时整句会被按另一门语言硬解，
  /// 出来的原文完全不沾边——知道自己在说什么语言就该钉死。
  Future<void> pickLanguage() async {
    if (state.recording.value || state.starting.value) {
      return;
    }
    if (await AiModelSwitch.pickLanguage()) {
      await loadModels();
    }
  }

  /// 换合成音色。kokoro 有 53 个声音，默认那个未必好听，这是最直接的补救。
  Future<void> pickVoice() async {
    if (state.recording.value || state.starting.value) {
      return;
    }
    if (await AiModelSwitch.pickVoice()) {
      await loadModels();
    }
  }

  /// 去模型管理页下载/删除，回来重新读一遍——那边也能改选中项。
  Future<void> openModelSettings() async {
    if (state.recording.value || state.starting.value) {
      return;
    }
    await Nav.scSettingsAi.push();
    await loadModels();
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

      // ---- 4. 起两个 isolate（模型加载要几百毫秒到几秒，必须在开录之前完成，
      //         否则最开始那段音频会堆在流里）。
      if (!await _startVad()) {
        return;
      }
      if (!await _startInfer()) {
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
        // **这条是整个连续录音能不能成立的关键**。
        // 默认值是 AudioInterruptionMode.pause——"自动暂停，手动恢复"。
        // 我们自己播译文就会引发一次音频焦点变化，录音器收到后把自己暂停并销毁
        // （logcat 里能看到 onAudioFocusChange(-3) 紧跟着 AudioRecord stop +
        // AudioEffect Destructor），而没有任何人去恢复它。表现就是：说完第一句、
        // 译文播完，之后再说话完全没反应，必须重启 App。
        // none = 中断时录音状态不变，这正是沉浸式连续跟读需要的。
        audioInterruption: AudioInterruptionMode.none,
      ));
      _audioSub = stream.listen(
        _onAudio,
        onError: (Object e) {
          state.error.value = '$e';
        },
        // 录音流被系统掐掉时（焦点、拔耳机、厂商省电策略）这里会走到。
        // 不处理的话表现是"还显示在录音，但再也切不出段"——最难查的那种。
        onDone: () {
          if (state.recording.value) {
            state.error.value = I18nKey.aiRecordInterrupted.tr;
            debugPrint('record stream closed while still recording');
          }
        },
      );

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
        // usage 用 media 而不是 voiceCommunication：后者会把声音路由到**听筒**
        // （logcat: onAudioDeviceUpdate AUDIO_DEVICE_OUT_EARPIECE），
        // 手机不贴耳边根本听不见译文。回声由下面的硬静音闸兜底，不靠路由来防。
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.media,
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

  Future<bool> _startInfer() async {
    try {
      final catalog = await AiCatalog.load();
      final missing = await AiPipeline.missingRole(catalog);
      if (missing != null) {
        state.error.value = I18nKey.aiModelMissing.trArgs([missing.label]);
        return false;
      }
      final build = await AiPipeline.prepare(catalog);
      if (build == null) {
        state.error.value = I18nKey.aiModelMissing.trArgs([AiRole.asr.label]);
        return false;
      }
      _infer = await InferIsolate.start(build);
      _inferSub = _infer!.results.listen(_onInferResult, onError: (Object e) {
        state.error.value = '$e';
      });
      return true;
    } catch (e) {
      debugPrint('infer start failed: $e');
      state.error.value = '$e';
      return false;
    }
  }

  Future<void> _onInferResult(InferResult result) async {
    final session = state.session;
    if (session == null) {
      return;
    }
    final seg = session.segments.where((e) => e.index == result.index).firstOrNull;
    if (seg == null) {
      return;
    }
    if (!result.ok) {
      seg.state = RecordSegmentState.failed;
      debugPrint('infer failed for ${result.index}: ${result.error}');
    } else {
      if (result.src != null) seg.src = result.src!;
      if (result.dst != null) seg.dst = result.dst!;
      if (result.ttsPath != null) {
        // session.json 里存相对文件名，整个会话目录搬走也不会失效
        seg.tts = result.ttsPath!.split('/').last;
        seg.ttsMs = result.ttsMs;
      }
      seg.state = RecordSegmentState.done;
    }
    await session.save();
    state.segments.refresh();

    if (result.ok && seg.state == RecordSegmentState.done) {
      // 译文就绪：两下短震，跟"切好一段"的一下长震区分开，
      // 这样息屏时不用睁眼也知道进行到哪一步了。
      unawaited(HapticFeedback.selectionClick());
      if (state.autoPlay.value && seg.tts.isNotEmpty) {
        unawaited(_playTts(session.pathOf(seg.tts), seg.ttsMs));
      }
    }
  }

  /// 播译文。播之前先把麦克风输入闸掉，免得把自己放出去的声音当成用户在说话。
  ///
  /// 平台的 AEC（voiceCommunication）在多数机器上够用，但有些机器的 AEC 是摆设，
  /// 这个硬闸是兜底。宁可闸多一点：闸门期间用户说的话会丢，但那期间正在放音，
  /// 用户本来也不会说话。
  Future<void> _playTts(String path, int ms) async {
    try {
      muteFor(ms);
      await _ttsPlayer.setFilePath(path);
      await _ttsPlayer.seek(Duration.zero);
      // 不 await play()：just_audio 的 play() 要等整段放完才 resolve，
      // await 它会把后面那段的结果处理一起卡住。
      unawaited(_ttsPlayer.play());
    } catch (e) {
      debugPrint('play tts failed: $e');
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
      // 落完盘才入队。推理是严格串行的，说得比推理快只会让队列变长，不会丢段。
      _infer?.submit(InferJob(
        index: record.index,
        kind: InferJobKind.full,
        samples: seg.samples,
        outWavPath: session.pathOf('${record.index.toString().padLeft(4, '0')}.tts.wav'),
      ));
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
    // flush 是异步投递的，等一小会儿让最后那段从 isolate 回来并落盘、入队
    await Future<void>.delayed(const Duration(milliseconds: 400));

    await exitBlackScreen();
    // 排空推理队列再拆 isolate。停的时候队列里通常还堆着几段——
    // 直接 dispose 会把它们连同已经落盘的音频一起变成永远 pending 的孤儿。
    await _drainInfer();
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
    await _openReview(session);
  }

  /// 打开复核页，回来之后把采集页也收掉。
  ///
  /// 两种回来方式要区别对待：复核页提交或丢弃后会自己 until 回素材页，那时采集页
  /// 早被弹掉了，再 back 一次会把素材页也弹了；用户单纯按返回时采集页还在，
  /// 必须收掉——否则它停在"已停止但攥着一个会话"的状态，再点开始会新建一个会话，
  /// 把刚才那个变成孤儿。所以用当前路由判断，而不是猜。
  Future<void> _openReview(RecordSession session) async {
    final myRoute = Nav.scCrMaterialRecord.path;
    await Nav.scCrMaterialRecordReview.push(arguments: [state.book, session.dir]);
    if (Get.currentRoute == myRoute) {
      state.session = null;
      Nav.back();
    }
  }

  /// 上次没做完的会话。息屏录到一半被系统杀掉时，音频都还在盘上，
  /// 把人直接领去复核页，而不是让他重录。
  Future<void> checkUnfinished() async {
    try {
      final list = await RecordSession.findUnfinished();
      final mine = list.where((e) => e.bookId == state.book.id).toList();
      if (mine.isEmpty || Get.context == null) {
        return;
      }
      final session = mine.first;
      MsgBox.yesOrNo(
        title: I18nKey.aiChapterFromRecord.tr,
        desc: I18nKey.aiReviewResume.tr,
        yes: () {
          Get.back();
          _openReview(session);
        },
        no: () async {
          Get.back();
          await session.discard();
        },
        noBtnTitle: I18nKey.aiReviewDiscard.tr,
      );
    } catch (e) {
      debugPrint('checkUnfinished failed: $e');
    }
  }

  /// 等推理队列做完。
  ///
  /// 上限是防呆：某一段把 worker 卡死时不能让用户永远退不出去，
  /// 超时后剩下的段仍是 pending，复核页可以单独重试。
  Future<void> _drainInfer({Duration timeout = const Duration(minutes: 5)}) async {
    final session = state.session;
    if (session == null || _infer == null) {
      return;
    }
    state.draining.value = true;
    final deadline = DateTime.now().add(timeout);
    try {
      while (session.pendingCount > 0 && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    } finally {
      state.draining.value = false;
    }
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
    await _inferSub?.cancel();
    _inferSub = null;
    await _infer?.dispose();
    _infer = null;
    try {
      await _ttsPlayer.stop();
    } catch (e) {
      debugPrint('teardown tts player failed: $e');
    }
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
