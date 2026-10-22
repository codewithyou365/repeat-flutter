import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/logic/ai/ai_remote.dart';
import 'package:repeat_flutter/logic/ai/shadow_remote.dart';
import 'package:repeat_flutter/logic/ai/infer_engine.dart';
import 'package:repeat_flutter/logic/ai/infer_isolate.dart';
import 'package:repeat_flutter/logic/ai/wav.dart';

/// 用假的 runOne 顶掉真正的 HTTP，只测队列和回退的编排。
class _FakeRemote extends RemoteInferEngine {
  final Future<InferResult> Function(InferJob job) handler;
  final List<int> seen = [];

  _FakeRemote(this.handler, {super.onDown, super.maxInFlight})
      : super(baseUrl: 'http://x', params: const AiRemoteParams(language: 'zh'));

  @override
  Future<InferResult> runOne(InferJob job) {
    seen.add(job.index);
    return handler(job);
  }
}

InferJob job(int i, [InferJobKind kind = InferJobKind.full]) => InferJob(index: i, kind: kind);

void main() {
  group('RemoteInferEngine 队列', () {
    test('并发不超过 maxInFlight，每个 job 恰好一个结果', () async {
      var now = 0, peak = 0;
      final e = _FakeRemote((j) async {
        now++;
        peak = peak > now ? peak : now;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        now--;
        return InferResult(index: j.index, kind: j.kind, src: 's${j.index}');
      });
      final got = <int>[];
      final sub = e.results.listen((r) => got.add(r.index));
      for (var i = 0; i < 6; i++) {
        e.submit(job(i));
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
      // 顺序不保证（结果靠 index 认领），但一个不能少、一个不能多
      expect(got.toSet(), {0, 1, 2, 3, 4, 5});
      expect(got.length, 6);
      expect(peak, 2, reason: '默认 maxInFlight=2');
      await sub.cancel();
      await e.dispose();
    });

    test('maxInFlight=1 时退化成严格串行', () async {
      var now = 0, peak = 0;
      final e = _FakeRemote((j) async {
        now++;
        peak = peak > now ? peak : now;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        now--;
        return InferResult(index: j.index, kind: j.kind);
      }, maxInFlight: 1);
      final got = <int>[];
      final sub = e.results.listen((r) => got.add(r.index));
      for (var i = 0; i < 4; i++) {
        e.submit(job(i));
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(peak, 1);
      expect(got, [0, 1, 2, 3], reason: '串行时顺序应当保持');
      await sub.cancel();
      await e.dispose();
    });

    test('单段失败不拖垮队列', () async {
      final e = _FakeRemote((j) async {
        if (j.index == 1) throw const AiRemoteRejected('model not installed on server');
        return InferResult(index: j.index, kind: j.kind, src: 's');
      });
      final got = <InferResult>[];
      final sub = e.results.listen(got.add);
      e.submit(job(0));
      e.submit(job(1));
      e.submit(job(2));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(got.map((r) => r.index).toSet(), {0, 1, 2});
      final byIndex = {for (final r in got) r.index: r};
      expect(byIndex[1]!.ok, false);
      expect(byIndex[1]!.error, contains('model not installed'));
      expect(byIndex[2]!.ok, true);
      await sub.cancel();
      await e.dispose();
    });
  });

  group('回退判定', () {
    test('AiRemoteDown 触发接管，AiRemoteRejected 不触发', () async {
      final takenOver = <int>[];
      Future<bool> onDown(InferJob j, Object e) async {
        takenOver.add(j.index);
        return true;
      }

      final e = _FakeRemote((j) async {
        if (j.index == 0) throw const AiRemoteRejected('bad params');
        throw const AiRemoteDown('connection refused');
      }, onDown: onDown);

      final got = <InferResult>[];
      final sub = e.results.listen(got.add);
      e.submit(job(0));
      e.submit(job(1));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      // 4xx 那条走普通失败路径，没有被接管
      expect(takenOver, [1]);
      expect(got.first.index, 0);
      expect(got.first.error, contains('bad params'));
      await sub.cancel();
      await e.dispose();
    });

    test('确认挂了之后，队列里剩下的直接交接，不再一条条撞超时', () async {
      var calls = 0;
      Future<bool> onDown(InferJob j, Object e) async => true;
      final e = _FakeRemote((j) async {
        calls++;
        throw const AiRemoteDown('timeout');
      }, onDown: onDown);
      e.submit(job(0));
      e.submit(job(1));
      e.submit(job(2));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      // 确认挂掉之后，队列里剩下的直接交接，不再一条条撞超时。
      // maxInFlight=2，所以最坏是最初并发的那两条都真发了请求。
      expect(calls, lessThanOrEqualTo(2));
      expect(e.seen, isNot(contains(2)));
      await e.dispose();
    });
  });

  group('AiRemote.normalize', () {
    test('补协议和默认端口', () {
      expect(AiRemote.normalize('192.168.1.2'), 'http://192.168.1.2:8767');
      expect(AiRemote.normalize(' 192.168.1.2:9000 '), 'http://192.168.1.2:9000');
      expect(AiRemote.normalize('http://mac.local:8767/'), 'http://mac.local:8767');
      expect(AiRemote.normalize('https://mac.local:443'), 'https://mac.local:443');
      expect(AiRemote.normalize(''), '');
    });
  });

  group('ShadowRemote.normalize', () {
    test('默认端口补的是 8766，不是 8767', () {
      // 两个服务是独立进程、独立端口。补错端口的表现是"填了地址却连不上"，
      // 而且错得很隐蔽——8767 上确实有个服务在应答，只是它不会打分。
      expect(ShadowRemote.normalize('192.168.1.2'), 'http://192.168.1.2:8766');
      expect(ShadowRemote.normalize(' 192.168.1.2:9100 '), 'http://192.168.1.2:9100');
      expect(ShadowRemote.normalize('http://mac.local:8766/'), 'http://mac.local:8766');
      // Uri 会把协议默认端口规范化掉，hasPort 在这里是 false，
      // 靠 authority 里有没有冒号判断才不会补成 :443:8766
      expect(ShadowRemote.normalize('https://mac.local:443'), 'https://mac.local:443');
      expect(ShadowRemote.normalize(''), '');
    });
  });

  group('Wav.encode', () {
    test('编出来的字节能被 Wav.read 原样读回去', () async {
      final samples = Float32List.fromList(List.generate(800, (i) => (i % 100) / 100 - 0.5));
      final bytes = Wav.encode(samples);
      expect(bytes.length, Wav.headerSize + samples.length * 2);
      // 头里的采样率要对，不然服务端会按错的速率解码
      final view = ByteData.view(Uint8List.fromList(bytes).buffer);
      expect(view.getUint32(24, Endian.little), Wav.sampleRate);

      final dir = await Directory.systemTemp.createTemp('wav_encode');
      try {
        final path = '${dir.path}/a.wav';
        await File(path).writeAsBytes(bytes);
        final back = await Wav.read(path);
        expect(back, isNotNull);
        expect(back!.length, samples.length);
        for (var i = 0; i < samples.length; i++) {
          expect(back[i], closeTo(samples[i], 1 / 32767));
        }
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
