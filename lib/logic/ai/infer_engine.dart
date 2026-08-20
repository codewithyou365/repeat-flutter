import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:repeat_flutter/logic/ai/ai_remote.dart';
import 'package:repeat_flutter/logic/ai/infer_isolate.dart';
import 'package:repeat_flutter/logic/ai/wav.dart';

/// 识别/翻译/合成的执行方。录音页和复核页只认这个接口，不关心活是机内 isolate
/// 干的还是局域网里的电脑干的。
///
/// 面很窄，因为原来的 [InferIsolate] 对外也就这三样（pendingCount 是从
/// RecordSession 的段落状态算出来的，不在引擎上）。
abstract class InferEngine {
  Stream<InferResult> get results;

  void submit(InferJob job);

  Future<void> dispose();
}

/// 机内推理。就是原来那条路，一个字没改，只是套了层壳。
class LocalInferEngine implements InferEngine {
  final InferIsolate _isolate;

  LocalInferEngine._(this._isolate);

  static Future<LocalInferEngine> start(InferInit Function(SendPort) build) async {
    return LocalInferEngine._(await InferIsolate.start(build));
  }

  @override
  Stream<InferResult> get results => _isolate.results;

  @override
  void submit(InferJob job) => _isolate.submit(job);

  /// 投一个 job 并等它的结果。回退路径要用：那边是串行 await 的调用方式。
  ///
  /// 靠 index+kind 认领结果是安全的，因为调用方一次只跑一个。
  Future<InferResult> run(InferJob job) {
    final done = Completer<InferResult>();
    late StreamSubscription<InferResult> sub;
    sub = _isolate.results.listen((r) {
      if (r.index == job.index && r.kind == job.kind && !done.isCompleted) {
        done.complete(r);
        sub.cancel();
      }
    }, onError: (Object e) {
      if (!done.isCompleted) {
        done.completeError(e);
        sub.cancel();
      }
    });
    _isolate.submit(job);
    return done.future;
  }

  @override
  Future<void> dispose() => _isolate.dispose();
}

/// 作业队列，最多 [maxInFlight] 个同时在跑。远程和回退两个引擎共用。
///
/// 为什么要自己排队：执行器是 async 的，不卡一道就会把几十段一次全投出去。
///
/// **为什么可以并发（而不是严格串行）**：结果是靠 [InferResult.index] 认领的
/// （录音页 `_onInferResult` 按 index 找段落，复核页一次只跑一段），所以回来的
/// 先后不影响正确性。段落列表的顺序在录音时就定了，推理只是往里填字段。
///
/// 服务端那边合成是用实例池并行的（占整段 94% 的时间），客户端不并发的话
/// 池子永远只有一个实例在动，等于白开。
mixin _JobQueue {
  final _queue = <InferJob>[];
  int _running = 0;
  bool _stopped = false;

  StreamController<InferResult> get controller;

  /// 同时在跑的上限。1 就退化成严格串行。
  int get maxInFlight => 1;

  Future<InferResult> exec(InferJob job);

  void enqueue(InferJob job) {
    if (_stopped) {
      return;
    }
    _queue.add(job);
    _pump();
  }

  void _pump() {
    while (!_stopped && _queue.isNotEmpty && _running < maxInFlight) {
      final job = _queue.removeAt(0);
      _running++;
      unawaited(_run(job));
    }
  }

  Future<void> _run(InferJob job) async {
    InferResult r;
    try {
      r = await exec(job);
    } catch (e) {
      // 单段失败不能拖垮队列：后面的段还得接着做，
      // 失败的那段在复核页会显示成 failed 并给一个重试按钮。
      r = InferResult(index: job.index, kind: job.kind, error: '$e');
    } finally {
      _running--;
    }
    if (!controller.isClosed) {
      controller.add(r);
    }
    _pump();
  }

  Future<void> stopQueue() async {
    _stopped = true;
    _queue.clear();
    if (!controller.isClosed) {
      await controller.close();
    }
  }
}

/// 远程推理。把音频 POST 给 server/ai，文本和合成好的 wav 一起回来。
class RemoteInferEngine with _JobQueue implements InferEngine {
  final String baseUrl;
  final AiRemoteParams params;

  /// 服务端不可用（连不上/超时/5xx）时的回调。给 [FallbackInferEngine] 挂钩用。
  ///
  /// 返回 true 表示这个 job 已经被接管了，队列这边就不要再产出结果。
  final Future<bool> Function(InferJob job, Object error)? onDown;

  @override
  final StreamController<InferResult> controller = StreamController<InferResult>.broadcast();

  /// 同时发几个请求。2 是照着服务端 TTS 实例池的默认大小来的
  /// （REPEAT_AI_TTS_WORKERS，也是 2）——再多就只是排在服务端队列里，
  /// 白占手机的内存和连接。
  @override
  final int maxInFlight;

  RemoteInferEngine({
    required this.baseUrl,
    required this.params,
    this.onDown,
    this.maxInFlight = 2,
  });

  @override
  Stream<InferResult> get results => controller.stream;

  @override
  void submit(InferJob job) => enqueue(job);

  /// 已经确认服务端挂了。队列里剩下的 job 就别再一个个去撞 5 秒超时了，
  /// 直接交给接管方。
  bool _dead = false;

  @override
  Future<InferResult> exec(InferJob job) async {
    if (_dead && onDown != null && await onDown!(job, const AiRemoteDown('remote already down'))) {
      return InferResult(index: job.index, kind: job.kind, error: _handedOff);
    }
    try {
      return await runOne(job);
    } on AiRemoteDown catch (e) {
      _dead = true;
      if (onDown != null && await onDown!(job, e)) {
        // 已交给本地跑，结果由那边发出去，这里必须什么都不产出——
        // 否则同一段会出现两条结果，后到的那条会把好结果覆盖成 failed。
        return InferResult(index: job.index, kind: job.kind, error: _handedOff);
      }
      rethrow;
    }
  }

  /// 队列里被接管的 job 用这个错误码占位，[_SerialQueue] 之外看不到。
  static const String _handedOff = '__handed_off__';

  Future<InferResult> runOne(InferJob job) async {
    // 4xx（模型没装、参数不对）是业务错误：换本地跑结果一样，所以让它走
    // 正常的失败路径，不触发回退。这个区分在 AiRemote 里用两种异常表达。
    try {
      final resp = await AiRemote.infer(
        baseUrl,
        kind: job.kind.name,
        params: params,
        wav: job.samples == null ? null : Wav.encode(job.samples!),
        text: job.text,
        timeout: job.kind == InferJobKind.full ? const Duration(seconds: 90) : const Duration(seconds: 60),
      );
      var ttsMs = 0;
      String? ttsPath;
      if (resp.ttsWav != null && resp.ttsWav!.isNotEmpty && job.outWavPath != null) {
        // 服务端返回的是完整 wav（采样率跟 TTS 模型走，melo 是 44.1k），
        // 原样落盘就行，不用再解一遍头。
        await File(job.outWavPath!).writeAsBytes(resp.ttsWav!, flush: true);
        ttsPath = job.outWavPath;
        ttsMs = resp.ttsMs;
      }
      return InferResult(
        index: job.index,
        kind: job.kind,
        src: resp.src,
        dst: resp.dst,
        ttsPath: ttsPath,
        ttsMs: ttsMs,
      );
    } on AiRemoteRejected catch (e) {
      return InferResult(index: job.index, kind: job.kind, error: '$e');
    }
  }

  @override
  Future<void> dispose() => stopQueue();
}

/// 优先远程，服务端挂了就自动切回机内模型。
///
/// 只有网络类错误才回退：4xx 说明服务端明确拒绝了（模型没装、参数不对），
/// 换本地跑结果一样，回退只会白等一遍。
///
/// 一旦切过去就不再试远程了。录音过程中反复探活会让每一段都先卡 5 秒超时，
/// 比"从此用本地"糟得多；用户修好服务端后重进一次录音页即可。
class FallbackInferEngine implements InferEngine {
  final String baseUrl;
  final AiRemoteParams params;
  final InferInit Function(SendPort) buildLocal;

  /// 第一次回退时回调一次，用来提示用户"已切回本地"。
  final void Function()? onFellBack;

  final StreamController<InferResult> _controller = StreamController<InferResult>.broadcast();
  late final RemoteInferEngine _remote;
  LocalInferEngine? _local;
  bool _fellBack = false;
  StreamSubscription<InferResult>? _sub;

  FallbackInferEngine({
    required this.baseUrl,
    required this.params,
    required this.buildLocal,
    this.onFellBack,
  }) {
    _remote = RemoteInferEngine(baseUrl: baseUrl, params: params, onDown: _takeOver);
    _sub = _remote.results.listen((r) {
      // 被接管的那条占位结果不往外发
      if (r.error == RemoteInferEngine._handedOff) {
        return;
      }
      if (!_controller.isClosed) {
        _controller.add(r);
      }
    }, onError: (Object e) {
      if (!_controller.isClosed) {
        _controller.addError(e);
      }
    });
  }

  @override
  Stream<InferResult> get results => _controller.stream;

  @override
  void submit(InferJob job) {
    final local = _local;
    if (local != null) {
      // 已经切到本地了，绕开远程队列直接投
      unawaited(_runLocal(job));
      return;
    }
    _remote.submit(job);
  }

  Future<bool> _takeOver(InferJob job, Object error) async {
    debugPrint('remote infer down, falling back to local: $error');
    if (!await _ensureLocal()) {
      // 机内也没有模型可用：这段就是做不成，让它按普通失败走
      return false;
    }
    if (!_fellBack) {
      _fellBack = true;
      onFellBack?.call();
    }
    unawaited(_runLocal(job));
    return true;
  }

  /// 起本地 isolate 的在途 future。并发时两路同时回退会各起一个 isolate——
  /// 多驻留一份模型（几百 MB），还漏掉一个没人关。用它把并发收敛成一次。
  Future<bool>? _localStarting;

  Future<bool> _ensureLocal() {
    if (_local != null) {
      return Future.value(true);
    }
    return _localStarting ??= () async {
      try {
        _local = await LocalInferEngine.start(buildLocal);
        return true;
      } catch (e) {
        debugPrint('local fallback start failed: $e');
        return false;
      } finally {
        // 失败要允许下一次重试；成功了上面那个 _local != null 会先短路
        _localStarting = null;
      }
    }();
  }

  Future<void> _runLocal(InferJob job) async {
    final local = _local;
    if (local == null) {
      return;
    }
    InferResult r;
    try {
      r = await local.run(job);
    } catch (e) {
      r = InferResult(index: job.index, kind: job.kind, error: '$e');
    }
    if (!_controller.isClosed) {
      _controller.add(r);
    }
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _remote.dispose();
    await _local?.dispose();
    _local = null;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
