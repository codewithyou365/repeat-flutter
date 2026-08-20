import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:repeat_flutter/logic/ai/translate_engine.dart';
import 'package:repeat_flutter/logic/ai/wav.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

enum InferJobKind {
  /// 识别 + 翻译 + 合成，录音时每切出一段走的就是这条
  full,

  /// 只重新识别（复核页用）
  asr,

  /// 只重新翻译（复核页用）
  mt,

  /// 只重新合成。文本可能是用户在复核页改过的，所以不带音频。
  tts,
}

class InferJob {
  final int index;
  final InferJobKind kind;

  /// asr/mt/full 要的原始采样，16kHz 单声道
  final Float32List? samples;

  /// tts 要合成的文本
  final String? text;

  /// tts 输出的 wav 落在哪儿。让 worker 直接写盘，几百 KB 的采样就不用跨 isolate 传了。
  final String? outWavPath;

  const InferJob({
    required this.index,
    required this.kind,
    this.samples,
    this.text,
    this.outWavPath,
  });
}

class InferResult {
  final int index;
  final InferJobKind kind;

  /// null 表示这次没产出这一项（比如只跑了 tts）
  final String? src;
  final String? dst;
  final String? ttsPath;
  final int ttsMs;
  final String? error;

  const InferResult({
    required this.index,
    required this.kind,
    this.src,
    this.dst,
    this.ttsPath,
    this.ttsMs = 0,
    this.error,
  });

  bool get ok => error == null;
}

class InferInit {
  final SendPort port;

  /// 已解析成绝对路径的 OfflineRecognizerConfig json
  final Map<String, dynamic> asrCfg;

  /// 翻译用的 config。跟 asrCfg 是同一份模型时 [shareRecognizer] 为 true。
  final Map<String, dynamic> mtCfg;

  /// 已解析成绝对路径的 OfflineTtsConfig json
  final Map<String, dynamic> ttsCfg;

  /// 识别和翻译选的是同一个模型：共用一个 recognizer 实例，靠 setConfig 切 task，
  /// 否则同一份 whisper 会被加载两遍，内存直接翻倍。
  final bool shareRecognizer;

  final int ttsSid;
  final double ttsSpeed;

  const InferInit({
    required this.port,
    required this.asrCfg,
    required this.mtCfg,
    required this.ttsCfg,
    required this.shareRecognizer,
    this.ttsSid = 0,
    this.ttsSpeed = 1.0,
  });
}

enum _InferCommand { stop }

/// 识别 / 翻译 / 语音合成都跑在这一个 isolate 里，严格串行。
///
/// 为什么单独一个 isolate：sherpa 的 Dart API 是同步 FFI，一次解码会把所在 isolate
/// 阻塞一到三秒。放主 isolate 会同时丢录音块和掉帧；跟 VAD 共用会让"切好一句"的
/// 震动反馈排在上一段推理后面，息屏时用户就完全失去反馈了。
///
/// 为什么不用多个 isolate 并行推理：模型是按 isolate 加载的，两个推理 isolate 等于
/// 两份模型驻留，内存直接翻倍——而内存正是这条链路最紧的资源。
///
/// FIFO 队列不用自己写：isolate 的消息队列本身就是 FIFO，而 FFI 调用是同步的，
/// 所以投进来的 job 天然按顺序一个一个做完。录音期间说得比推理快只会让队列变长，
/// 不会丢段——因为音频在投递之前就已经落盘了。
class InferIsolate {
  final Isolate _isolate;
  final SendPort _commands;
  final ReceivePort _events;
  final StreamController<InferResult> _controller;

  InferIsolate._(this._isolate, this._commands, this._events, this._controller);

  Stream<InferResult> get results => _controller.stream;

  static Future<InferIsolate> start(InferInit Function(SendPort) build) async {
    final events = ReceivePort();
    final isolate = await Isolate.spawn(_entry, build(events.sendPort), debugName: 'infer');

    final controller = StreamController<InferResult>.broadcast();
    final ready = Completer<SendPort>();

    events.listen((msg) {
      if (msg is SendPort) {
        if (!ready.isCompleted) ready.complete(msg);
      } else if (msg is InferResult) {
        controller.add(msg);
      } else if (msg is String) {
        // 初始化阶段的致命错误（模型加载不了），必须让上层知道
        if (!ready.isCompleted) {
          ready.completeError(msg);
        } else {
          controller.addError(msg);
        }
      }
    });

    try {
      // 模型加载可能要几秒（whisper-small 的 decoder 就 250MB），给足超时
      final commands = await ready.future.timeout(const Duration(seconds: 120));
      return InferIsolate._(isolate, commands, events, controller);
    } catch (e) {
      isolate.kill(priority: Isolate.immediate);
      events.close();
      await controller.close();
      rethrow;
    }
  }

  void submit(InferJob job) => _commands.send(job);

  Future<void> dispose() async {
    _commands.send(_InferCommand.stop);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // 队列里可能还堆着 job，stop 排在它们后面，所以直接杀。
    // 模型内存随 isolate 一起回收，不会泄漏。
    _isolate.kill(priority: Isolate.immediate);
    _events.close();
    if (!_controller.isClosed) await _controller.close();
  }
}

void _entry(InferInit init) {
  final commands = ReceivePort();

  sherpa.OfflineRecognizer? asr;
  TranslateEngine? mt;
  sherpa.OfflineTts? tts;

  try {
    // 每个 isolate 都有自己的一份 FFI 绑定状态，必须各自 init 一次
    sherpa.initBindings();
  } catch (e) {
    init.port.send('infer init failed: $e');
    commands.close();
    return;
  }

  final asrConfig = sherpa.OfflineRecognizerConfig.fromJson(init.asrCfg);
  final mtConfig = sherpa.OfflineRecognizerConfig.fromJson(init.mtCfg);
  final ttsConfig = sherpa.OfflineTtsConfig.fromJson(init.ttsCfg);

  // 三个模型都懒加载：只重新合成一段音频时没必要把 whisper 也拉进内存。
  // 内存是这条链路最紧的资源，能不驻留就不驻留。
  sherpa.OfflineRecognizer ensureAsr() => asr ??= sherpa.OfflineRecognizer(asrConfig);

  TranslateEngine ensureMt() {
    if (mt != null) {
      return mt!;
    }
    if (init.shareRecognizer) {
      // 同一份模型：共用 ASR 那个实例，每次翻译前 setConfig 切成 task=translate，
      // 完事切回 asrConfig。不这么做的话 whisper-small 要加载两遍。
      mt = WhisperTranslateEngine(
        recognizer: ensureAsr(),
        translateConfig: mtConfig,
        restoreConfig: asrConfig,
        owned: false,
      );
    } else {
      mt = WhisperTranslateEngine(
        recognizer: sherpa.OfflineRecognizer(mtConfig),
        translateConfig: mtConfig,
        owned: true,
      );
    }
    return mt!;
  }

  sherpa.OfflineTts ensureTts() => tts ??= sherpa.OfflineTts(ttsConfig);

  String runAsr(Float32List samples) {
    final r = ensureAsr();
    final stream = r.createStream();
    try {
      stream.acceptWaveform(samples: samples, sampleRate: Wav.sampleRate);
      r.decode(stream);
      return r.getResult(stream).text.trim();
    } finally {
      stream.free();
    }
  }

  /// 返回合成音频的时长(ms)。0 表示没合成出东西。
  Future<int> runTts(String text, String outPath) async {
    if (text.isEmpty) {
      return 0;
    }
    final audio = ensureTts().generate(text: text, sid: init.ttsSid, speed: init.ttsSpeed);
    if (audio.samples.isEmpty) {
      return 0;
    }
    // TTS 的采样率跟录音的 16k 不一定一样（melo-tts 是 44.1k），
    // 必须按模型自己报的采样率写头，否则播出来是变调的。
    await Wav.write(outPath, audio.samples, rate: audio.sampleRate);
    return Wav.durationMs(audio.samples.length, rate: audio.sampleRate);
  }

  Future<void> handle(InferJob job) async {
    String? src;
    String? dst;
    String? ttsPath;
    var ttsMs = 0;
    try {
      switch (job.kind) {
        case InferJobKind.asr:
          src = runAsr(job.samples!);
          break;
        case InferJobKind.mt:
          dst = ensureMt().translate(samples: job.samples, text: job.text);
          break;
        case InferJobKind.tts:
          if (job.outWavPath != null) {
            ttsMs = await runTts(job.text ?? '', job.outWavPath!);
            if (ttsMs > 0) ttsPath = job.outWavPath;
          }
          break;
        case InferJobKind.full:
          src = runAsr(job.samples!);
          dst = ensureMt().translate(samples: job.samples, text: src);
          if (job.outWavPath != null) {
            ttsMs = await runTts(dst, job.outWavPath!);
            if (ttsMs > 0) ttsPath = job.outWavPath;
          }
          break;
      }
      init.port.send(InferResult(
        index: job.index,
        kind: job.kind,
        src: src,
        dst: dst,
        ttsPath: ttsPath,
        ttsMs: ttsMs,
      ));
    } catch (e) {
      // 单段失败不能拖垮整个 worker：后面的段还得接着做，
      // 失败的那段在复核页会显示成 failed 并给一个重试按钮。
      init.port.send(InferResult(index: job.index, kind: job.kind, error: '$e'));
    }
  }

  // 自己排一条队，而不是把 handle 直接挂在 listen 的 async 回调上。
  //
  // ReceivePort 的流**不会**等 async 回调返回就投递下一条消息，而 handle 里
  // 写 tts wav 那一步有 await，于是两个 job 会在写文件那一刻交错——
  // 说好的"严格串行"就没了，结果回来的顺序也不再可控。
  // 这里用队列 + 单飞标志把串行做实。
  final queue = <InferJob>[];
  var processing = false;
  var stopping = false;

  Future<void> pump() async {
    if (processing) {
      return;
    }
    processing = true;
    try {
      while (queue.isNotEmpty && !stopping) {
        await handle(queue.removeAt(0));
      }
    } finally {
      processing = false;
    }
  }

  commands.listen((msg) {
    if (msg is InferJob) {
      queue.add(msg);
      // 不 await：listen 的回调保持同步，排队和消费彻底分开
      unawaited(pump());
    } else if (msg == _InferCommand.stop) {
      stopping = true;
      queue.clear();
      try {
        mt?.unload();
        // mt 跟 asr 共用实例时 unload 不会 free，这里再 free 一次是安全的
        asr?.free();
        tts?.free();
      } catch (e) {
        debugPrint('infer teardown failed: $e');
      }
      commands.close();
      Isolate.exit();
    }
  });

  init.port.send(commands.sendPort);
}
