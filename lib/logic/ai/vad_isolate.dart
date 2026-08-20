import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// VAD 切出来的一段语音。
class VadSegment {
  /// [-1,1] 的采样，16kHz 单声道
  final Float32List samples;

  /// 这一段在整条流里的起始采样下标
  final int startSample;

    const VadSegment({required this.samples, required this.startSample});

  int get durationMs => (samples.length * 1000 / 16000).round();
}

/// 判停跑在自己的 isolate 里。
///
/// 为什么不跟推理共用一个 isolate：sherpa_onnx 的 Dart API 是**同步 FFI**，
/// 一次 ASR/TTS 解码会把所在 isolate 整个阻塞一到三秒。判停要是排在推理后面，
/// "这一句切好了"的震动反馈就会迟到好几秒——而息屏场景下用户只有这个反馈可依赖。
/// silero 每 32ms 的帧只要 ~1ms，它这个 isolate 97% 的时间是空闲的。
///
/// 为什么不干脆放主 isolate：主 isolate 要收 record 的 EventChannel 事件、要刷 UI，
/// 被同步 FFI 卡住会同时丢音频块和掉帧。
///
/// 模型句柄不跨 isolate：sherpa 的对象都是指向本 isolate 原生内存的 Pointer。
/// 这里只传配置（Map）过去，worker 自己 initBindings 自己建模型；
/// 回来的也只有 Float32List/int 这种可传的东西。
class VadIsolate {
  final Isolate _isolate;
  final SendPort _commands;
  final ReceivePort _events;
  final StreamController<VadSegment> _controller;

  VadIsolate._(this._isolate, this._commands, this._events, this._controller);

  Stream<VadSegment> get segments => _controller.stream;

  /// [cfg] 是已经解析成绝对路径的 VadModelConfig json（见 AiModelPaths.resolve）。
  static Future<VadIsolate> start(Map<String, dynamic> cfg, {double bufferSeconds = 30}) async {
    final events = ReceivePort();
    final isolate = await Isolate.spawn(
      _entry,
      _VadInit(events.sendPort, cfg, bufferSeconds),
      debugName: 'vad',
    );

    final controller = StreamController<VadSegment>.broadcast();
    final ready = Completer<SendPort>();

    events.listen((msg) {
      if (msg is SendPort) {
        // worker 起来后先把它的命令口回传，之后才敢往里灌音频
        if (!ready.isCompleted) ready.complete(msg);
      } else if (msg is _VadSegmentMsg) {
        controller.add(VadSegment(samples: msg.samples, startSample: msg.startSample));
      } else if (msg is _VadErrorMsg) {
        // 模型加载失败这种，必须让上层知道，不能默默不出段
        controller.addError(msg.message);
        if (!ready.isCompleted) ready.completeError(msg.message);
      }
    });

    try {
      final commands = await ready.future.timeout(const Duration(seconds: 30));
      return VadIsolate._(isolate, commands, events, controller);
    } catch (e) {
      isolate.kill(priority: Isolate.immediate);
      events.close();
      await controller.close();
      rethrow;
    }
  }

  /// 灌一块 PCM 采样。非阻塞，切出段来会从 [segments] 冒出来。
  void accept(Float32List samples) => _commands.send(samples);

  /// 丢掉内部缓冲。播放反馈音时用它，免得把自己放出去的声音当成用户在说话。
  void reset() => _commands.send(_VadCommand.reset);

  /// 收尾：把最后那段还没等到静音的语音也吐出来，否则用户说的最后一句会被吞掉。
  void flush() => _commands.send(_VadCommand.flush);

  Future<void> dispose() async {
    _commands.send(_VadCommand.stop);
    // 给 worker 一点时间自己退，超时就硬杀——反正模型内存随 isolate 一起没
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _isolate.kill(priority: Isolate.beforeNextEvent);
    _events.close();
    if (!_controller.isClosed) await _controller.close();
  }
}

enum _VadCommand { reset, flush, stop }

class _VadInit {
  final SendPort port;
  final Map<String, dynamic> cfg;
  final double bufferSeconds;

  const _VadInit(this.port, this.cfg, this.bufferSeconds);
}

class _VadSegmentMsg {
  final Float32List samples;
  final int startSample;

  const _VadSegmentMsg(this.samples, this.startSample);
}

class _VadErrorMsg {
  final String message;

  const _VadErrorMsg(this.message);
}

void _entry(_VadInit init) {
  final commands = ReceivePort();
  sherpa.VoiceActivityDetector? created;

  try {
    // 每个 isolate 都有自己的一份 FFI 绑定状态，必须各自 init 一次；
    // 在别处 init 过对这里没有任何用（sherpa_onnx 包文档明确写了这一点）。
    sherpa.initBindings();
    final config = sherpa.VadModelConfig.fromJson(init.cfg);
    final vad = sherpa.VoiceActivityDetector(config: config, bufferSizeInSeconds: init.bufferSeconds);
    created = vad;

    final windowSize = config.sileroVad.windowSize;
    // sherpa 的 VAD 要求每次正好喂一个窗口的采样，而录音回调给的块大小是任意的，
    // 所以这里自己攒一个余料缓冲，凑够一窗喂一窗，剩下的留到下一块。
    var pending = Float32List(0);

    void drain() {
      while (!vad.isEmpty()) {
        final seg = vad.front();
        vad.pop();
        if (seg.samples.isNotEmpty) {
          init.port.send(_VadSegmentMsg(seg.samples, seg.start));
        }
      }
    }

    void feed(Float32List incoming) {
      if (pending.isNotEmpty) {
        final merged = Float32List(pending.length + incoming.length);
        merged.setAll(0, pending);
        merged.setAll(pending.length, incoming);
        incoming = merged;
      }
      var offset = 0;
      while (incoming.length - offset >= windowSize) {
        vad.acceptWaveform(Float32List.sublistView(incoming, offset, offset + windowSize));
        offset += windowSize;
        drain();
      }
      pending = Float32List.fromList(Float32List.sublistView(incoming, offset));
    }

    commands.listen((msg) {
      try {
        if (msg is Float32List) {
          feed(msg);
        } else if (msg == _VadCommand.reset) {
          vad.reset();
          pending = Float32List(0);
        } else if (msg == _VadCommand.flush) {
          // 不足一窗的余料先补零凑满，否则最后那点采样永远进不去 VAD，
          // 表现就是用户说的最后一句话整段消失。
          if (pending.isNotEmpty) {
            final padded = Float32List(windowSize)..setAll(0, pending);
            vad.acceptWaveform(padded);
            pending = Float32List(0);
          }
          vad.flush();
          drain();
        } else if (msg == _VadCommand.stop) {
          vad.free();
          commands.close();
          Isolate.exit();
        }
      } catch (e) {
        init.port.send(_VadErrorMsg('vad worker: $e'));
      }
    });

    init.port.send(commands.sendPort);
  } catch (e) {
    init.port.send(_VadErrorMsg('vad init failed: $e'));
    created?.free();
    commands.close();
  }
}
