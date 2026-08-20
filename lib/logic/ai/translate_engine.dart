import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// 翻译这一环的接缝。
///
/// 接口是**同步**的，不是 Future：实现跑在推理 isolate 里，底下是 sherpa 的同步 FFI，
/// 包一层 Future 只会假装它可以被 await 让出，实际照样把整个 isolate 阻塞住。
///
/// 现在只有 [WhisperTranslateEngine] 一个实现。留这个接缝是因为翻译是整条流水线上
/// 唯一有真实不确定性的一环：Whisper 的 translate 任务只能译成英文，将来要接
/// 本地小 LLM（任意语向）或别的方案时，流水线不用动。
abstract class TranslateEngine {
  /// 存进 K.aiTranslateEngine 的值，只能往后加不能改名
  String get id;

  /// 引擎要的是音频还是文本。whisper 是重新解码音频，LLM 类是拿识别出的文本。
  /// 复核页"改完原文重新翻译"时要看这个：needsAudio 的引擎改原文不影响译文。
  bool get needsAudio;

  String translate({String? text, Float32List? samples, int sampleRate = 16000});

  void unload();
}

/// 用 Whisper 的 task=translate 直接吐英文。
///
/// 好处是识别和翻译共用一份模型文件，不用第二个运行时、不用第二份下载、完全离线。
/// 代价是每段音频要解码两遍（transcribe 拿原文、translate 拿译文），且只能译成英文。
///
/// **关于 recognizer 的复用**：当识别和翻译选的是同一个模型时（比如轻量档只装了
/// whisper-base），这里跟 ASR 共用同一个 recognizer 实例，靠 [sherpa.OfflineRecognizer.setConfig]
/// 在每次解码前把 task 切过去——否则同一份 whisper-small 要加载两遍，内存直接翻倍
/// （decoder 单个就 250MB）。高质量档用 SenseVoice 做识别、Whisper 只做翻译，
/// 两个不同模型各自一个实例，走不到这条复用路径。
class WhisperTranslateEngine implements TranslateEngine {
  @override
  String get id => 'whisper';

  @override
  bool get needsAudio => true;

  final sherpa.OfflineRecognizer _recognizer;

  /// 翻译用的 config（task=translate）。跟 ASR 共用实例时，每次解码前要用它 setConfig。
  final sherpa.OfflineRecognizerConfig _translateConfig;

  /// 跟 ASR 共用实例时，用完要把 config 切回去的那一份
  final sherpa.OfflineRecognizerConfig? _restoreConfig;

  /// 是不是自己独占这个 recognizer。共用时不能 free，否则把 ASR 一起干掉了。
  final bool _owned;

  WhisperTranslateEngine({
    required sherpa.OfflineRecognizer recognizer,
    required sherpa.OfflineRecognizerConfig translateConfig,
    sherpa.OfflineRecognizerConfig? restoreConfig,
    required bool owned,
  })  : _recognizer = recognizer,
        _translateConfig = translateConfig,
        _restoreConfig = restoreConfig,
        _owned = owned;

  @override
  String translate({String? text, Float32List? samples, int sampleRate = 16000}) {
    if (samples == null || samples.isEmpty) {
      return '';
    }
    if (_restoreConfig != null) {
      _recognizer.setConfig(_translateConfig);
    }
    try {
      final stream = _recognizer.createStream();
      try {
        stream.acceptWaveform(samples: samples, sampleRate: sampleRate);
        _recognizer.decode(stream);
        return _recognizer.getResult(stream).text.trim();
      } finally {
        stream.free();
      }
    } finally {
      // 无论成败都要切回去，否则下一次识别会拿到英文而不是原文
      if (_restoreConfig != null) {
        _recognizer.setConfig(_restoreConfig);
      }
    }
  }

  @override
  void unload() {
    if (_owned) {
      _recognizer.free();
    }
  }
}
