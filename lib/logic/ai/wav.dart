import 'dart:io';
import 'dart:typed_data';

/// 16kHz 单声道 PCM16 的 WAV 读写。
///
/// 为什么自己写而不用包：整个流水线里 WAV 只有一种形状（VAD 切出来的那种），
/// 44 字节的头手写比引一个依赖清楚。录音原始流是 PCM16，模型要的是 Float32，
/// 两边的转换也都在这里，省得散在各处各写一遍。
class Wav {
  static const int sampleRate = 16000;
  static const int numChannels = 1;
  static const int bitsPerSample = 16;
  static const int headerSize = 44;

  /// record 插件给的是裸 PCM16 字节流，模型要的是 [-1,1] 的 Float32。
  ///
  /// 注意字节序：Android/iOS 的 PCM16 都是小端，这里按小端读。
  static Float32List pcm16ToFloat32(Uint8List bytes) {
    // 奇数长度说明这一块正好切在一个采样中间，丢掉尾巴那个半截字节，
    // 不然后面所有采样的高低位都会错开一个字节，整段变成噪音。
    final count = bytes.lengthInBytes ~/ 2;
    final view = ByteData.view(bytes.buffer, bytes.offsetInBytes, count * 2);
    final out = Float32List(count);
    for (var i = 0; i < count; i++) {
      out[i] = view.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }

  static Uint8List float32ToPcm16(Float32List samples) {
    final out = ByteData(samples.length * 2);
    for (var i = 0; i < samples.length; i++) {
      // 模型输出偶尔会略微越界，不夹住的话 toInt() 会绕回成反相的爆音
      var v = samples[i];
      if (v > 1.0) v = 1.0;
      if (v < -1.0) v = -1.0;
      out.setInt16(i * 2, (v * 32767).round(), Endian.little);
    }
    return out.buffer.asUint8List();
  }

  static Uint8List header(int dataBytes, {int rate = sampleRate}) {
    final b = ByteData(headerSize);
    void ascii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        b.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    final byteRate = rate * numChannels * bitsPerSample ~/ 8;
    ascii(0, 'RIFF');
    b.setUint32(4, 36 + dataBytes, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    b.setUint32(16, 16, Endian.little); // fmt 块长度
    b.setUint16(20, 1, Endian.little); // 1 = PCM，无压缩
    b.setUint16(22, numChannels, Endian.little);
    b.setUint32(24, rate, Endian.little);
    b.setUint32(28, byteRate, Endian.little);
    b.setUint16(32, numChannels * bitsPerSample ~/ 8, Endian.little);
    b.setUint16(34, bitsPerSample, Endian.little);
    ascii(36, 'data');
    b.setUint32(40, dataBytes, Endian.little);
    return b.buffer.asUint8List();
  }

  static Future<void> write(String path, Float32List samples, {int rate = sampleRate}) async {
    final pcm = float32ToPcm16(samples);
    final sink = File(path).openWrite();
    try {
      sink.add(header(pcm.lengthInBytes, rate: rate));
      sink.add(pcm);
    } finally {
      await sink.close();
    }
  }

  /// 读回采样。只认这里 [write] 写出来的那种 16 位单声道 WAV，
  /// 复核页"重新识别/重新翻译"要拿原始采样再喂一次模型。
  static Future<Float32List?> read(String path) async {
    final f = File(path);
    if (!await f.exists()) {
      return null;
    }
    final bytes = await f.readAsBytes();
    if (bytes.length <= headerSize) {
      return null;
    }
    return pcm16ToFloat32(Uint8List.sublistView(bytes, headerSize));
  }

  /// 采样数换成毫秒。写 verse 的 start/end 要用。
  static int durationMs(int sampleCount, {int rate = sampleRate}) {
    return (sampleCount * 1000 / rate).round();
  }
}
