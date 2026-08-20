import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:repeat_flutter/common/foreground_service.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
import 'package:repeat_flutter/logic/ai/ai_pipeline.dart';
import 'package:repeat_flutter/logic/ai/ai_remote.dart';
import 'package:repeat_flutter/logic/ai/infer_engine.dart';
import 'package:repeat_flutter/logic/ai/infer_isolate.dart';
import 'package:repeat_flutter/logic/ai/shadow_remote.dart';
import 'package:repeat_flutter/logic/ai/wav.dart';

/// 跟读录音 + 打分的状态机。
///
/// **为什么是 start / stop / 轮询三段式，而不是一个"录完给我分数"的调用**：
/// JsRuntime.invoke 给每个 Game.* 只有 5 秒（handlePromise 的 timeout），超时会
/// 返回 500 并且**泄漏一个 20ms 的 Timer.periodic**；网页那边 ws.ts 还有一层
/// 10 秒超时。而一次"听→录→打分"是 5~30 秒，任何阻塞式的实现都必然撞上这两道墙。
/// 所以这里全部方法立刻返回，游戏靠 shadowStatus 轮询拿进度。
///
/// 生命周期挂在 JsRuntime 上，JsRuntime.dispose() 会调 dispose()。
class ShadowRecorder {
  final AudioRecorder _recorder = AudioRecorder();

  /// idle / recording / scoring / done / failed
  String _state = 'idle';

  /// 每次 start()/cancel() 自增。打分结果回来时对不上就丢弃——
  /// 用户放弃这一轮、去了下一句，迟到的分数不能糊到新句子上。
  int _token = 0;

  final BytesBuilder _buf = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _sub;
  Timer? _maxTimer;
  int _startedAtMs = 0;
  int _stoppedAtMs = 0;
  double _levelDb = -60;

  Map<String, dynamic>? _result;
  String _error = '';
  bool _degraded = false;

  /// 远程打分服务挂了。**本轮 App 生命周期内 sticky、单向**，和
  /// FallbackInferEngine 一个道理：不 sticky 的话每一句都要白等 5 秒连接超时。
  bool _remoteDown = false;

  InferEngine? _fallbackEngine;

  bool get isRecording => _state == 'recording';

  /// 开录。返回 'ok' / 'no_permission' / 'busy' / 'error: ...'
  Future<String> start({int maxMs = 15000}) async {
    if (_state == 'recording' || _state == 'scoring') {
      return 'busy';
    }
    _token++;
    _state = 'recording';
    _buf.clear();
    _result = null;
    _error = '';
    _degraded = false;
    _levelDb = -60;

    try {
      // ---- 1. 权限必须在最前。Android 14+ 没拿到 RECORD_AUDIO 就起
      //         麦克风前台服务会直接抛 SecurityException。
      if (!await _ensureMicPermission()) {
        _state = 'idle';
        return 'no_permission';
      }

      // ---- 2. 前台服务，**必须在页面还可见的时候起**。
      //         Android 11+ 的 while-in-use 规则会把后台启动的麦克风前台服务
      //         静默静音——不抛异常，只是从此录到的全是零。
      //         顺序是死的：权限 → 前台服务 → startStream。
      await ForegroundService.start(kind: ForegroundKind.record);

      // ---- 3. 音频会话。跟读是"先放参考音、紧接着录"，音频焦点会变，
      //         配置不对就会跟自己打架。
      await _configureAudioSession();

      // ---- 4. 开录。
      final stream = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: Wav.sampleRate,
        numChannels: Wav.numChannels,
        // voiceCommunication 走平台的 AEC/AGC/NS 管线，顺带把采样率钳到
        // 16k 单声道——正好是打分服务要的格式，省掉一次重采样。
        androidConfig: AndroidRecordConfig(audioSource: AndroidAudioSource.voiceCommunication),
        echoCancel: true,
        noiseSuppress: true,
        // autoGain 会压掉动态范围，对发音评测是纯损失（GOP 靠的就是细微差别）。
        autoGain: false,
        // **这条是关键**。默认 AudioInterruptionMode.pause 是"自动暂停、手动恢复"，
        // 而我们紧挨着录音之前刚播完参考 TTS，那次音频焦点变化会让录音器把自己
        // 暂停并销毁，却没有任何人去恢复它。症状：第一句能录，之后再按录音毫无反应。
        // none = 中断时录音状态不变。
        audioInterruption: AudioInterruptionMode.none,
      ));

      _sub = stream.listen(
        _onAudio,
        onError: (Object e) {
          _error = '$e';
          _state = 'failed';
        },
        // 录音流被系统掐掉（焦点、拔耳机、厂商省电）时走这里。不处理的话
        // 表现是"还显示在录音，但永远出不来结果"——最难查的那种。
        onDone: () {
          if (_state == 'recording') {
            _error = 'record stream closed';
            _state = 'failed';
            _releaseSession();
          }
        },
      );

      _startedAtMs = DateTime.now().millisecondsSinceEpoch;
      // 到点自动停，这是"麦克风忘了关"的三条保险之一
      //（另外两条：网页 onBeforeUnmount 调 cancel、JsRuntime.dispose）。
      _maxTimer = Timer(Duration(milliseconds: maxMs), () {
        if (_state == 'recording') {
          _autoStop();
        }
      });
      return 'ok';
    } catch (e) {
      _state = 'failed';
      _error = '$e';
      await _releaseSession();
      return 'error: $e';
    }
  }

  void _onAudio(Uint8List chunk) {
    _buf.add(chunk);
    // 电平条：取这一块的峰值。PCM16 小端。
    var peak = 0;
    final n = chunk.length - 1;
    for (var i = 0; i + 1 < n; i += 64) {
      // 每 32 个采样看一个就够画条了，逐样本扫是白烧 CPU
      final v = (chunk[i + 1] << 8) | chunk[i];
      final s = (v & 0x8000) != 0 ? v - 0x10000 : v;
      final a = s.abs();
      if (a > peak) peak = a;
    }
    _levelDb = peak <= 0 ? -60.0 : math.max(-60.0, 20 * (math.log(peak / 32768.0) / math.ln10));
  }

  /// 待打分文本由 stopAndScore 传进来；自动停时我们没有文本，
  /// 只把录音停掉并停在 recording 之后的中间态，等游戏那边调 stopRecord。
  String? _pendingText;

  void _autoStop() {
    final text = _pendingText;
    if (text != null) {
      stopAndScore(text);
    } else {
      // 游戏还没告诉我们参考文本。先把麦克风放掉，保留缓冲，
      // 等 stopRecord 上来直接打分。
      _stoppedAtMs = DateTime.now().millisecondsSinceEpoch;
      _stopStream();
      _state = 'recorded';
    }
  }

  /// 停录并开始打分。**立刻返回**，结果通过 status() 轮询取。
  String stopAndScore(String text) {
    if (_state != 'recording' && _state != 'recorded') {
      return 'not_recording';
    }
    if (_state == 'recording') {
      _stoppedAtMs = DateTime.now().millisecondsSinceEpoch;
      _stopStream();
    }
    _state = 'scoring';
    final token = _token;
    final pcm = _buf.toBytes();
    // 不 await：这个方法必须在 5 秒预算内返回。
    unawaited(_score(token, pcm, text));
    return 'ok';
  }

  Future<void> cancel() async {
    _token++;
    _pendingText = null;
    _stopStream();
    _buf.clear();
    _state = 'idle';
    _result = null;
    _error = '';
    await _releaseSession();
  }

  void _stopStream() {
    _maxTimer?.cancel();
    _maxTimer = null;
    _sub?.cancel();
    _sub = null;
    unawaited(_recorder.stop().catchError((Object e) {
      debugPrint('shadow recorder stop failed: $e');
      return null;
    }));
  }

  Future<void> _releaseSession() async {
    try {
      await ForegroundService.stop(kind: ForegroundKind.record);
    } catch (e) {
      debugPrint('shadow foreground stop failed: $e');
    }
  }

  Future<void> _score(int token, Uint8List pcm, String text) async {
    try {
      // PCM16 直接套个 wav 头就是服务端要的格式，不用绕 Float32 一圈。
      final wav = BytesBuilder(copy: false)
        ..add(Wav.header(pcm.length))
        ..add(pcm);
      final bytes = wav.toBytes();

      Map<String, dynamic>? out;

      if (!_remoteDown && await ShadowRemote.enabled()) {
        final baseUrl = await ShadowRemote.url();
        try {
          final s = await ShadowRemote.score(baseUrl, wav: bytes, text: text);
          out = s.toJson();
        } on AiRemoteRejected catch (e) {
          // 服务端明确拒绝（文本为空、音频太短、模型没装）。本地也做不了，
          // 不回退——把服务端的话原样给用户看，比一个瞎猜的分数有用。
          _finish(token, null, '$e', false);
          return;
        } on AiRemoteDown catch (e) {
          debugPrint('shadow remote down, fall back: $e');
          _remoteDown = true;
        }
      }

      if (out == null) {
        out = await _degradedScore(pcm, text);
        if (out == null) {
          _finish(token, null, 'no_engine', false);
          return;
        }
      }

      _finish(token, out, '', out['degraded'] == true);
    } catch (e) {
      _finish(token, null, '$e', false);
    }
  }

  void _finish(int token, Map<String, dynamic>? result, String error, bool degraded) {
    // 这一轮已经被放弃了（用户重来或者换了句子），迟到的结果直接丢。
    if (token != _token) {
      return;
    }
    _result = result;
    _error = error;
    _degraded = degraded;
    _state = result != null ? 'done' : 'failed';
    unawaited(_releaseSession());
  }

  /// 降级：用本地/远程 ASR 转一遍，跟参考文本做词级比对。
  ///
  /// 这条路**给不出发音质量**——whisper 会自动纠错，你把 think 读成 sink 它照样
  /// 转出 think。所以它只是"服务挂了也别让游戏卡死"的兜底，结果一律标 degraded，
  /// UI 上必须显示出来。
  Future<Map<String, dynamic>?> _degradedScore(Uint8List pcm, String text) async {
    try {
      _fallbackEngine ??= await AiPipeline.createEngine(await AiCatalog.load());
      final engine = _fallbackEngine;
      if (engine == null) {
        return null;
      }
      final res = await engine.runAndWait(InferJob(
        index: 0,
        kind: InferJobKind.asr,
        samples: Wav.pcm16ToFloat32(pcm),
      ));
      if (!res.ok || (res.src ?? '').isEmpty) {
        return null;
      }
      return _compareWords(res.src!, text, pcm.length);
    } catch (e) {
      debugPrint('shadow degraded score failed: $e');
      return null;
    }
  }

  static final RegExp _wordRe = RegExp(r"[a-z0-9']+");

  Map<String, dynamic> _compareWords(String heard, String ref, int pcmBytes) {
    List<String> norm(String s) => _wordRe.allMatches(s.toLowerCase()).map((m) => m[0]!).toList();
    final h = norm(heard);
    final r = norm(ref);

    // 逐词编辑距离，顺便标出哪些参考词没被读到。
    final n = r.length, m = h.length;
    final d = List.generate(n + 1, (i) => List<int>.filled(m + 1, 0));
    for (var i = 0; i <= n; i++) {
      d[i][0] = i;
    }
    for (var j = 0; j <= m; j++) {
      d[0][j] = j;
    }
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        final c = r[i - 1] == h[j - 1] ? 0 : 1;
        d[i][j] = math.min(math.min(d[i - 1][j] + 1, d[i][j - 1] + 1), d[i - 1][j - 1] + c);
      }
    }
    final hit = List<bool>.filled(n, false);
    var i = n, j = m;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && d[i][j] == d[i - 1][j - 1] + (r[i - 1] == h[j - 1] ? 0 : 1)) {
        hit[i - 1] = r[i - 1] == h[j - 1];
        i--;
        j--;
      } else if (i > 0 && d[i][j] == d[i - 1][j] + 1) {
        i--;
      } else {
        j--;
      }
    }

    final matched = hit.where((e) => e).length;
    final acc = n == 0 ? 0.0 : 100.0 * (1 - d[n][m] / n).clamp(0.0, 1.0);
    final comp = n == 0 ? 0.0 : 100.0 * matched / n;
    // 流利度这条路判断不了，给中位数并靠 degraded 标注说明情况。
    const flu = 50.0;

    // 用和服务端一样的默认权重，保证两条路的总分尺度大致可比。
    final overall = 0.60 * acc + 0.25 * comp + 0.15 * flu;

    final refWords = _wordRe.allMatches(ref.toLowerCase()).toList();
    return {
      'overall': overall.round(),
      'accuracy': acc.round(),
      'completeness': comp.round(),
      'fluency': flu.round(),
      'durationMs': Wav.durationMs(pcmBytes ~/ 2),
      'speechMs': 0,
      'degraded': true,
      'mismatch': false,
      'words': [
        for (var k = 0; k < refWords.length && k < n; k++)
          {
            'w': ref.substring(refWords[k].start, refWords[k].end),
            'start': 0,
            'end': 0,
            'score': hit[k] ? 90 : 30,
            'level': hit[k] ? 'good' : 'bad',
            'missed': !hit[k],
            // 没有音素信息。UI 上"点词看音素"这一层在降级时自然就是空的。
            'phones': const [],
          }
      ],
      'missedWords': [
        for (var k = 0; k < refWords.length && k < n; k++)
          if (!hit[k]) ref.substring(refWords[k].start, refWords[k].end)
      ],
      'insertions': 0,
      'per': 0,
      'unmappedPhones': const [],
      'heard': heard,
    };
  }

  /// 游戏轮询它。**同步方法**：只读内存状态，不做任何 IO。
  Map<String, dynamic> status() {
    var elapsed = 0;
    if (_state == 'recording') {
      elapsed = DateTime.now().millisecondsSinceEpoch - _startedAtMs;
    } else if (_startedAtMs > 0 && _stoppedAtMs > 0) {
      elapsed = _stoppedAtMs - _startedAtMs;
    }
    return {
      'state': _state,
      'token': _token,
      'elapsedMs': elapsed,
      'levelDb': _levelDb.round(),
      'degraded': _degraded,
      'remoteDown': _remoteDown,
      'result': _result,
      'error': _error,
    };
  }

  /// 让游戏在开录时就把参考文本交上来，这样 maxMs 自动停也能直接进打分。
  void setPendingText(String text) {
    _pendingText = text;
  }

  Future<void> dispose() async {
    await cancel();
    try {
      await _recorder.dispose();
    } catch (e) {
      debugPrint('shadow recorder dispose failed: $e');
    }
    try {
      await _fallbackEngine?.dispose();
    } catch (e) {
      debugPrint('shadow fallback engine dispose failed: $e');
    }
    _fallbackEngine = null;
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
        // 参考音会小到听不见。mixWithOthers：不掐掉别人正在放的音频。
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker |
            AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        // usage 用 media 而不是 voiceCommunication：后者会把声音路由到听筒，
        // 手机不贴耳边根本听不见参考音。
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.media,
        ),
        // 不要独占焦点：抢焦点会跟自己的录音器打架。
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ));
      await session.setActive(true);
    } catch (e) {
      // 配不上不致命，录音多半照样能跑，只是回声/路由可能不理想。
      debugPrint('audio session configure failed: $e');
    }
  }
}
