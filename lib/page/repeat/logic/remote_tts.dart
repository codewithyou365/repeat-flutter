import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:repeat_flutter/common/domain_alias.dart';

/// 远程 TTS：把文本丢给 server/ai 的 /v1/tts（或别的回音频的 HTTP 服务），拿回音频播掉。
///
/// 音频写进临时目录的**同一个文件**再播，每次覆盖，不攒缓存——朗读文本千变万化，存下来也几乎复用不上。
/// 不用 StreamAudioSource 直接播内存字节：它在 Android 上是 just_audio 起一个 127.0.0.1 的
/// 本地 HTTP 代理让 ExoPlayer 去拉，而 ExoPlayer 走系统代理——手机 Wi-Fi 配了代理时，
/// 这个 127.0.0.1 请求会被转到代理机上，连不到、卡很久、最后 502（实测），白白回落到本机 TTS。
class RemoteTts {
  /// 链接里写了它就替换到那个位置走 GET（接参数名不一样的其它 TTS 服务）；
  /// 没写就 POST 表单 `text=`——长文本塞 URL 里既难看又可能超长，server/ai 的 /v1/tts 两种都认。
  static const String textPlaceholder = '{{text}}';

  AudioPlayer? _player;

  /// 每次 speak/stop 加一，正在跑的那轮发现对不上就收手，不再请求、不再播下一句
  int _gen = 0;

  /// 取音频并播完才返回（跟本机 TTS 的 awaitSpeakCompletion 一个节奏）。
  /// 第一句就失败（连不上 / 非 2xx / 回来的不是音频）才抛异常，由调用方决定回落本机；
  /// 已经念出声以后再失败就只记日志停下——这时回落会把整段从头再念一遍。
  ///
  /// **按句切开、边播边取**：服务端合成一整段要好几秒（123 字实测 3.6s），整段等完才出声太慢。
  /// 切句以后首句一两秒就能开口，后面的句子在前一句播放时就请求好了；
  /// 服务端合成速度约为音频时长的 0.4 倍，取下一句总比播当前句快，句间不会干等。
  ///
  /// 不用 just_audio 的 setUrl 直连：iOS 没开 NSAllowsArbitraryLoads，AVPlayer 拉明文 http
  /// 会被 ATS 拦掉；Dart 自己的 HttpClient 不受这个限制。
  Future<void> speak(String url, String text) async {
    final gen = ++_gen;
    final sw = Stopwatch()..start();
    final dio = Dio(BaseOptions(
      // 局域网内连不上应该立刻知道，别让用户干等
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.bytes,
      // 4xx 也要拿到 body 里的 error 文案，所以自己判状态码
      validateStatus: (_) => true,
    ));
    final parts = splitSentences(text);
    if (parts.isEmpty) return;
    final file = File(p.join((await getTemporaryDirectory()).path, 'remote_tts'));
    final player = _player ??= AudioPlayer();
    await player.stop();

    Future<_Audio> next = _fetch(dio, url, parts[0]);
    for (var i = 0; i < parts.length; i++) {
      final _Audio audio;
      try {
        audio = await next;
      } catch (e) {
        if (i == 0) rethrow;
        debugPrint('RemoteTts: part ${i + 1}/${parts.length} failed, stop here: $e');
        return;
      }
      if (gen != _gen) return;
      // 当前句开播前就把下一句发出去，播的时候服务端在合成
      if (i + 1 < parts.length) {
        next = _fetch(dio, url, parts[i + 1]);
        // 被 stop 打断时这个 future 没人等了，别让它的异常变成未处理错误
        next.ignore();
      }
      // 只用一个文件：写的时候上一句已经播完，不会覆盖正在播的
      final f = File('${file.path}${audio.ext}');
      await f.writeAsBytes(audio.bytes, flush: true);
      // **必须先 stop**：上一句播完后 just_audio 仍是 playing=true（只是 completed），
      // 这时 setFilePath 会自动开播、play() 立刻返回，循环就去等下一句并把这句半路切掉（实测每句只剩一半）
      await player.stop();
      await player.setFilePath(f.path);
      debugPrint('RemoteTts: part ${i + 1}/${parts.length} (${parts[i].length} chars) plays at ${sw.elapsedMilliseconds} ms');
      // play() 的 future 在播完或被 stop/pause 时才完成
      await player.play();
      if (gen != _gen) return;
    }
  }

  Future<void> stop() async {
    _gen++;
    await _player?.stop();
  }

  Future<_Audio> _fetch(Dio dio, String url, String text) async {
    final raw = url.trim();
    final sw = Stopwatch()..start();
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
    // 慢的时候看这行分辨是服务端合成慢还是本机播放慢
    debugPrint('RemoteTts: HTTP $code ${bytes.length} B in ${sw.elapsedMilliseconds} ms (${text.length} chars)');
    if (code < 200 || code >= 300) {
      throw Exception(_errorOf(code, bytes));
    }
    if (bytes.isEmpty) {
      throw Exception('empty audio');
    }
    return _Audio(bytes, _extOf(resp.headers.value(Headers.contentTypeHeader)));
  }

  /// 句末标点后切开；英文句点要后面跟空白才算（3.14、e.g. 不切）。
  /// 太长的句子再按逗号切，免得一句话又等好几秒；太短的并到下一句，每次请求都有固定开销。
  ///
  /// **第一句卡得更短**：开口快慢只取决于第一句的合成时间（31 字实测 2.8s），后面的句子
  /// 都是在前一句播放时合成的，长点无所谓。
  static List<String> splitSentences(String text) {
    const firstMaxLen = 16;
    const maxLen = 60;
    const minLen = 8;
    final sentences = text.split(RegExp(r'(?<=[。！？!?；;\n])|(?<=\.)(?=\s)'));
    final pieces = <String>[];
    for (final s in sentences) {
      if (s.length <= (pieces.every((e) => e.trim().isEmpty) ? firstMaxLen : maxLen)) {
        pieces.add(s);
      } else {
        pieces.addAll(s.split(RegExp(r'(?<=[，,、])')));
      }
    }
    final out = <String>[];
    var buf = '';
    for (final piece in pieces) {
      buf += piece;
      if (buf.trim().length >= minLen) {
        out.add(buf.trim());
        buf = '';
      }
    }
    if (buf.trim().isNotEmpty) {
      if (out.isEmpty) {
        out.add(buf.trim());
      } else {
        out[out.length - 1] = '${out.last}${buf.trimRight()}';
      }
    }
    return out;
  }

  /// 播放器按扩展名猜格式，所以文件名得跟上服务端回的类型；认不出的按 wav（server/ai 回的就是 wav）。
  static String _extOf(String? contentType) {
    final t = (contentType ?? '').toLowerCase();
    if (t.contains('mpeg') || t.contains('mp3')) return '.mp3';
    if (t.contains('ogg') || t.contains('opus')) return '.ogg';
    if (t.contains('aac') || t.contains('mp4') || t.contains('m4a')) return '.m4a';
    if (t.contains('flac')) return '.flac';
    return '.wav';
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

class _Audio {
  final Uint8List bytes;
  final String ext;

  _Audio(this.bytes, this.ext);
}
