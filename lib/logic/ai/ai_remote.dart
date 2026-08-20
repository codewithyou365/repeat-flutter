import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
import 'package:repeat_flutter/logic/ai/ai_model_help.dart';

/// 远程推理服务不可用：连不上、超时、5xx。
///
/// 和 [AiRemoteRejected] 分开是为了让上层能区分"该回退本地"和"这段就是做不了"。
/// 这条是前者。
class AiRemoteDown implements Exception {
  final String message;

  const AiRemoteDown(this.message);

  @override
  String toString() => message;
}

/// 服务端明确拒绝了这次请求（4xx）：模型没装、参数不对、wav 格式不对。
///
/// 换成本地跑大概率也是一样的结果，所以**不触发回退**，直接把这一段标成失败。
class AiRemoteRejected implements Exception {
  final String message;

  const AiRemoteRejected(this.message);

  @override
  String toString() => message;
}

/// /v1/health 的返回。
class AiRemoteHealth {
  final int latencyMs;
  final int proto;
  final int catalogVersion;

  /// 服务端已装好的模型 id，按角色分组
  final Map<String, List<String>> models;

  /// 服务端**当前生效**的模型名，按角色。选哪个模型由服务端决定，
  /// 手机只负责显示——理由见 [AiRemoteParams]。
  final Map<String, String> selection;

  const AiRemoteHealth({
    required this.latencyMs,
    required this.proto,
    required this.catalogVersion,
    required this.models,
    this.selection = const {},
  });

  List<String> of(AiRole role) => models[role.name] ?? const [];

  String nameOf(AiRole role) => selection[role.name] ?? '';
}

/// 一次远程推理里，**手机说了算**的那部分参数。
///
/// 只有语言。用哪个模型、哪个音色一律由服务端决定：手机的清单是
/// assets/ai/catalog.json，里面没有服务端专属的大模型（whisper-turbo 之类），
/// 让手机指定的话那些模型下下来也永远用不上。算力在哪，模型就在哪选。
///
/// 语言留在手机这边，是因为它说的是"我在说什么话"，跟算力无关；而且它决定
/// whisper translate 任务的**源语言**，不给的话模型会自己猜，猜错译文就跟着错。
class AiRemoteParams {
  /// 源语言。空串表示让模型自己判断。
  final String language;

  const AiRemoteParams({this.language = ''});

  Map<String, dynamic> toJson() => {'language': language};
}

/// /v1/infer 的返回。
class AiRemoteInferResponse {
  final String? src;
  final String? dst;
  final int ttsMs;
  final Uint8List? ttsWav;

  const AiRemoteInferResponse({this.src, this.dst, this.ttsMs = 0, this.ttsWav});
}

typedef AiUploadProgress = void Function(int fileIndex, int fileTotal, int bytesCount, int bytesTotal);

/// 局域网推理服务的客户端。服务端实现见仓库 server/ai，协议见 server/ai/PROTOCOL.md。
class AiRemote {
  static const int defaultPort = 8765;
  static const String urlHint = 'http://192.168.1.2:8765';

  static Future<String> url() async => (await Db().db.kvDao.getStr(K.aiRemoteUrl)) ?? '';

  static Future<void> setUrl(String v) async {
    await Db().db.kvDao.insertOrReplace(Kv(K.aiRemoteUrl, normalize(v)));
  }

  /// 开关打开**且**地址非空才算启用。少一个条件就会在录音时才发现连不上。
  static Future<bool> enabled() async {
    if ((await Db().db.kvDao.getStr(K.aiRemoteEnabled)) != '1') {
      return false;
    }
    return (await url()).isNotEmpty;
  }

  static Future<bool> switchOn() async => (await Db().db.kvDao.getStr(K.aiRemoteEnabled)) == '1';

  static Future<void> setEnabled(bool v) async {
    await Db().db.kvDao.insertOrReplace(Kv(K.aiRemoteEnabled, v ? '1' : '0'));
  }

  /// 用户多半只会填个 `192.168.1.2:8765`，甚至只填 IP。这里补齐成完整地址。
  ///
  /// [port] 是没写端口时补哪个。跟读打分服务在 8766，复用这个方法而不是
  /// 各写一份——下面那条 Uri.hasPort 的坑，复制一份就会重踩一次。
  static String normalize(String raw, {int port = defaultPort}) {
    var v = raw.trim();
    if (v.isEmpty) {
      return '';
    }
    if (!v.contains('://')) {
      v = 'http://$v';
    }
    // 末尾斜杠会让拼出来的路径变成 //v1/health，多数框架能忍，但没必要
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    // 不能用 Uri.hasPort 判断：Uri 会把协议的默认端口规范化掉，
    // `https://mac.local:443` 解析出来 hasPort 是 false，于是又被补成 `:443:8765`。
    // 直接看 authority 里有没有冒号最老实。
    final rest = v.substring(v.indexOf('://') + 3);
    final authority = rest.split('/').first;
    if (!authority.contains(':')) {
      v = '$v:$port';
    }
    return v;
  }

  static Dio _dio(String baseUrl, {Duration? timeout}) {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      // 局域网内连不上应该立刻知道，不要吊着录音
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: timeout ?? const Duration(seconds: 30),
      sendTimeout: timeout ?? const Duration(seconds: 30),
      // 4xx 也要拿到 body 里的 error 文案，所以自己判状态码
      validateStatus: (_) => true,
    ));
  }

  /// 把 dio 的异常/状态码翻译成 [AiRemoteDown] 或 [AiRemoteRejected]。
  static Never _fail(Object e) {
    if (e is AiRemoteDown || e is AiRemoteRejected) {
      throw e;
    }
    throw AiRemoteDown('$e');
  }

  static void _check(Response<dynamic> resp) {
    final code = resp.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      return;
    }
    final data = resp.data;
    var msg = 'HTTP $code';
    if (data is Map && data['error'] != null) {
      msg = '${data['error']}';
    } else if (data is Map && data['detail'] != null) {
      msg = '${data['detail']}';
    }
    if (code >= 400 && code < 500) {
      throw AiRemoteRejected(msg);
    }
    throw AiRemoteDown(msg);
  }

  /// 探活。顺便量往返延迟，设置页的"测试连接"显示它。
  static Future<AiRemoteHealth> health(String baseUrl) async {
    final start = DateTime.now();
    try {
      final resp = await _dio(baseUrl, timeout: const Duration(seconds: 5)).get<dynamic>('/v1/health');
      _check(resp);
      final data = resp.data;
      if (data is! Map) {
        throw const AiRemoteDown('bad health response');
      }
      final raw = data['models'];
      final models = <String, List<String>>{};
      if (raw is Map) {
        raw.forEach((k, v) {
          models['$k'] = v is List ? v.map((e) => '$e').toList() : <String>[];
        });
      }
      // selection 是 {role: {id, name, ...}}，只取 name 给界面显示
      final selection = <String, String>{};
      final rawSel = data['selection'];
      if (rawSel is Map) {
        rawSel.forEach((k, v) {
          if (v is Map && v['name'] != null) selection['$k'] = '${v['name']}';
        });
      }
      return AiRemoteHealth(
        latencyMs: DateTime.now().difference(start).inMilliseconds,
        proto: (data['proto'] as num?)?.toInt() ?? 0,
        catalogVersion: (data['catalogVersion'] as num?)?.toInt() ?? 0,
        models: models,
        selection: selection,
      );
    } catch (e) {
      _fail(e);
    }
  }

  /// 跑一次推理。[kind] 用的是 InferJobKind 的 name。
  static Future<AiRemoteInferResponse> infer(
    String baseUrl, {
    required String kind,
    required AiRemoteParams params,
    Uint8List? wav,
    String? text,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      final form = FormData.fromMap({
        'kind': kind,
        'params': jsonEncode(params.toJson()),
        'text': ?text,
        if (wav != null) 'audio': MultipartFile.fromBytes(wav, filename: 'a.wav'),
      });
      final resp = await _dio(baseUrl, timeout: timeout).post<dynamic>('/v1/infer', data: form);
      _check(resp);
      final data = resp.data;
      if (data is! Map) {
        throw const AiRemoteDown('bad infer response');
      }
      final b64 = data['ttsWav'];
      return AiRemoteInferResponse(
        src: data['src'] as String?,
        dst: data['dst'] as String?,
        ttsMs: (data['ttsMs'] as num?)?.toInt() ?? 0,
        ttsWav: b64 is String && b64.isNotEmpty ? base64Decode(b64) : null,
      );
    } catch (e) {
      _fail(e);
    }
  }

  // ---------------------------------------------------------------- 模型上传

  /// 服务端每个模型的状态：id -> 还缺哪些文件（空列表表示已装好）。
  static Future<Map<String, List<String>>> serverModels(String baseUrl) async {
    try {
      final resp = await _dio(baseUrl).get<dynamic>('/v1/models');
      _check(resp);
      final data = resp.data;
      final out = <String, List<String>>{};
      if (data is Map) {
        data.forEach((k, v) {
          if (v is Map) {
            final ok = v['ok'] == true;
            final missing = v['missing'];
            out['$k'] = ok ? <String>[] : (missing is List ? missing.map((e) => '$e').toList() : <String>['?']);
          }
        });
      }
      return out;
    } catch (e) {
      _fail(e);
    }
  }

  /// 把手机上装好的模型传给服务端。
  ///
  /// 直接遍历模型目录而不是照着清单的 files 列表走：zip 形式的模型（kokoro 带着
  /// 378 个 espeak 小文件）根本没有逐文件清单，只有目录里的东西才是真的。
  ///
  /// 返回传了几个文件。模型没装好会抛 [AiRemoteRejected]——半个模型传上去只会
  /// 让服务端也坏掉。
  static Future<int> upload(String baseUrl, AiModelEntry entry, {AiUploadProgress? onProgress}) async {
    if (!await AiModelHelp.isInstalled(entry.id)) {
      throw AiRemoteRejected('${entry.id} is not installed on this device');
    }
    final dir = await AiModelHelp.dirOf(entry.id);
    final files = <File>[];
    await for (final e in Directory(dir).list(recursive: true, followLinks: false)) {
      // .ok 不传：服务端要自己校验完才写，不然一个传坏的模型看着也是"装好了"
      if (e is File && !e.path.endsWith('/${AiModelHelp.okMarker}')) {
        files.add(e);
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));

    final dio = _dio(baseUrl, timeout: const Duration(minutes: 10));
    for (var i = 0; i < files.length; i++) {
      final f = files[i];
      final rel = f.path.substring(dir.length + 1);
      final total = await f.length();
      onProgress?.call(i, files.length, 0, total);
      try {
        final form = FormData.fromMap({
          'path': rel,
          'data': await MultipartFile.fromFile(f.path, filename: rel.split('/').last),
        });
        final resp = await dio.post<dynamic>(
          '/v1/models/${entry.id}/file',
          data: form,
          onSendProgress: (c, t) => onProgress?.call(i, files.length, c, t <= 0 ? total : t),
        );
        _check(resp);
      } catch (e) {
        _fail(e);
      }
    }

    try {
      final resp = await dio.post<dynamic>('/v1/models/${entry.id}/complete');
      _check(resp);
      final data = resp.data;
      if (data is Map && data['ok'] != true) {
        final missing = data['missing'];
        throw AiRemoteRejected('server still misses: ${missing is List ? missing.join(', ') : missing}');
      }
    } catch (e) {
      _fail(e);
    }
    return files.length;
  }
}
