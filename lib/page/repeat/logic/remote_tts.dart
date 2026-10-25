// StreamAudioSource 标着 experimental，但它是 just_audio 唯一不落盘就能播内存字节的办法。
// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:repeat_flutter/common/domain_alias.dart';

/// 远程 TTS：把文本丢给 server/ai 的 /v1/tts（或别的回音频的 HTTP 服务），
/// 拿回来的音频**只在内存里**播，不落盘——朗读文本千变万化，存下来也几乎复用不上。
class RemoteTts {
  /// 链接里写了它就替换到那个位置走 GET（接参数名不一样的其它 TTS 服务）；
  /// 没写就 POST 表单 `text=`——长文本塞 URL 里既难看又可能超长，server/ai 的 /v1/tts 两种都认。
  static const String textPlaceholder = '{{text}}';

  AudioPlayer? _player;

  /// 取音频并播完才返回（跟本机 TTS 的 awaitSpeakCompletion 一个节奏）。
  /// 连不上 / 非 2xx / 回来的不是音频都抛异常，由调用方决定回落本机。
  ///
  /// 不用 just_audio 的 setUrl 直连：iOS 没开 NSAllowsArbitraryLoads，AVPlayer 拉明文 http
  /// 会被 ATS 拦掉；Dart 自己的 HttpClient 不受这个限制。
  Future<void> speak(String url, String text) async {
    final raw = url.trim();
    final dio = Dio(BaseOptions(
      // 局域网内连不上应该立刻知道，别让用户干等
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.bytes,
      // 4xx 也要拿到 body 里的 error 文案，所以自己判状态码
      validateStatus: (_) => true,
    ));
    final Response<List<int>> resp;
    if (raw.contains(textPlaceholder)) {
      final uri = Uri.parse(raw.replaceAll(textPlaceholder, Uri.encodeComponent(text)));
      resp = await dio.getUri<List<int>>(await DomainAlias.resolveUri(uri));
    } else {
      final uri = Uri.parse(raw.contains('://') ? raw : 'http://$raw');
      // 链接里带的 ?sid=1&speed=1.2 也挪进表单，服务端 POST 只读表单
      resp = await dio.postUri<List<int>>(
        await DomainAlias.resolveUri(uri.replace(query: '')),
        data: {...uri.queryParameters, 'text': text},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
    }
    final bytes = Uint8List.fromList(resp.data ?? const []);
    final code = resp.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception(_errorOf(code, bytes));
    }
    if (bytes.isEmpty) {
      throw Exception('empty audio');
    }
    final player = _player ??= AudioPlayer();
    await player.stop();
    await player.setAudioSource(_BytesSource(bytes, resp.headers.value(Headers.contentTypeHeader) ?? 'audio/wav'));
    // play() 的 future 在播完或被 stop/pause 时才完成
    await player.play();
  }

  Future<void> stop() async {
    await _player?.stop();
  }

  static String _errorOf(int code, Uint8List body) {
    try {
      final data = jsonDecode(utf8.decode(body));
      if (data is Map && data['error'] != null) {
        return '${data['error']}';
      }
    } catch (_) {}
    return 'HTTP $code';
  }
}

/// 从内存字节喂给播放器，不写临时文件。
class _BytesSource extends StreamAudioSource {
  final Uint8List bytes;
  final String contentType;

  _BytesSource(this.bytes, this.contentType);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: contentType,
    );
  }
}
