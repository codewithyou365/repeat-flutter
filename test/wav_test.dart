import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/logic/ai/wav.dart';

void main() {
  test('PCM16 <-> Float32 往返，误差在一个量化步长内', () {
    final src = Float32List.fromList([0.0, 0.5, -0.5, 1.0, -1.0, 0.123456]);
    final back = Wav.pcm16ToFloat32(Wav.float32ToPcm16(src));
    expect(back.length, src.length);
    for (var i = 0; i < src.length; i++) {
      // 16 位量化步长是 1/32768，往返误差不该超过它
      expect((back[i] - src[i]).abs(), lessThan(1 / 32768 * 2), reason: 'i=$i');
    }
  });

  test('越界的采样会被夹住，而不是绕回成反相爆音', () {
    final back = Wav.pcm16ToFloat32(Wav.float32ToPcm16(Float32List.fromList([2.0, -2.0])));
    expect(back[0], greaterThan(0.99));
    expect(back[1], lessThan(-0.99));
  });

  test('半截字节被丢掉，不会让后面所有采样错位', () {
    // 5 个字节 = 2 个完整采样 + 1 个半截
    final odd = Uint8List.fromList([0x00, 0x40, 0x00, 0x80, 0x11]);
    expect(Wav.pcm16ToFloat32(odd).length, 2);
  });

  test('WAV 头字段正确，且能被自己读回来', () async {
    final dir = await Directory.systemTemp.createTemp('wav_test');
    try {
      final path = '${dir.path}/a.wav';
      // 一段 440Hz 正弦，长度不是整块，专门压边界
      final n = 16000 ~/ 3;
      final samples = Float32List.fromList(
          List.generate(n, (i) => sin(2 * pi * 440 * i / 16000) * 0.8));
      await Wav.write(path, samples);

      final bytes = await File(path).readAsBytes();
      expect(bytes.length, Wav.headerSize + n * 2);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');
      final bd = ByteData.sublistView(bytes);
      expect(bd.getUint32(4, Endian.little), 36 + n * 2, reason: 'RIFF chunk size');
      expect(bd.getUint16(20, Endian.little), 1, reason: 'PCM format');
      expect(bd.getUint16(22, Endian.little), 1, reason: 'mono');
      expect(bd.getUint32(24, Endian.little), 16000, reason: 'sample rate');
      expect(bd.getUint32(28, Endian.little), 32000, reason: 'byte rate');
      expect(bd.getUint16(34, Endian.little), 16, reason: 'bits per sample');
      expect(bd.getUint32(40, Endian.little), n * 2, reason: 'data size');

      final read = await Wav.read(path);
      expect(read, isNotNull);
      expect(read!.length, n);
      for (var i = 0; i < n; i++) {
        expect((read[i] - samples[i]).abs(), lessThan(1 / 32768 * 2));
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('时长换算', () {
    expect(Wav.durationMs(16000), 1000);
    expect(Wav.durationMs(8000), 500);
    expect(Wav.durationMs(0), 0);
  });

  test('读不存在或只有头的文件返回 null', () async {
    expect(await Wav.read('/definitely/not/here.wav'), isNull);
    final dir = await Directory.systemTemp.createTemp('wav_test2');
    try {
      final p = '${dir.path}/empty.wav';
      await File(p).writeAsBytes(Wav.header(0));
      expect(await Wav.read(p), isNull);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
