import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/logic/ai/ai_remote.dart';

/// 一个音素的分。
class ShadowPhone {
  /// IPA 符号
  final String p;
  final int start;
  final int end;
  final int score;

  /// 'ok' / 'sub' / 'del'，来自无约束解码和参考序列的编辑距离
  final String status;

  const ShadowPhone({
    required this.p,
    required this.start,
    required this.end,
    required this.score,
    required this.status,
  });

  factory ShadowPhone.fromJson(Map json) => ShadowPhone(
        p: '${json['p'] ?? ''}',
        start: (json['start'] as num?)?.toInt() ?? 0,
        end: (json['end'] as num?)?.toInt() ?? 0,
        score: (json['score'] as num?)?.toInt() ?? 0,
        status: '${json['status'] ?? 'ok'}',
      );

  Map<String, dynamic> toJson() => {
        'p': p,
        'start': start,
        'end': end,
        'score': score,
        'status': status,
      };
}

/// 一个词的分。
class ShadowWord {
  final String w;
  final int start;
  final int end;
  final int score;

  /// 'good' / 'fair' / 'bad'。**阈值由服务端定**，前端直接拿它上色——
  /// 前端自己定阈值的话，改校准要改两处。
  final String level;

  /// 漏读：这个词超过一半的音素是删除
  final bool missed;
  final List<ShadowPhone> phones;

  const ShadowWord({
    required this.w,
    required this.start,
    required this.end,
    required this.score,
    required this.level,
    required this.missed,
    required this.phones,
  });

  factory ShadowWord.fromJson(Map json) => ShadowWord(
        w: '${json['w'] ?? ''}',
        start: (json['start'] as num?)?.toInt() ?? 0,
        end: (json['end'] as num?)?.toInt() ?? 0,
        score: (json['score'] as num?)?.toInt() ?? 0,
        level: '${json['level'] ?? 'fair'}',
        missed: json['missed'] == true,
        phones: (json['phones'] as List? ?? const [])
            .whereType<Map>()
            .map(ShadowPhone.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'w': w,
        'start': start,
        'end': end,
        'score': score,
        'level': level,
        'missed': missed,
        'phones': phones.map((e) => e.toJson()).toList(),
      };
}

/// 一次打分的结果。
///
/// 字段和 server/shadow/PROTOCOL.md 的 /v1/score 一一对应。
class ShadowScore {
  final int overall;
  final int accuracy;
  final int completeness;
  final int fluency;
  final int durationMs;
  final int speechMs;

  /// 是不是本地 ASR 粗评分的结果。服务端永远返回 false，
  /// 只有手机端降级路径会置 true。
  final bool degraded;

  /// 读的根本不是这句。为 true 时 accuracy 已被服务端封顶。
  /// **UI 必须显式提示**，否则用户会以为是自己发音差。
  final bool mismatch;

  final List<ShadowWord> words;
  final List<String> missedWords;
  final int insertions;
  final double per;

  /// espeak 吐出了词表里没有的符号。非空说明 g2p 和模型词表失配，分数不可全信。
  final List<String> unmappedPhones;

  const ShadowScore({
    required this.overall,
    required this.accuracy,
    required this.completeness,
    required this.fluency,
    this.durationMs = 0,
    this.speechMs = 0,
    this.degraded = false,
    this.mismatch = false,
    this.words = const [],
    this.missedWords = const [],
    this.insertions = 0,
    this.per = 0,
    this.unmappedPhones = const [],
  });

  factory ShadowScore.fromJson(Map json) => ShadowScore(
        overall: (json['overall'] as num?)?.toInt() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toInt() ?? 0,
        completeness: (json['completeness'] as num?)?.toInt() ?? 0,
        fluency: (json['fluency'] as num?)?.toInt() ?? 0,
        durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
        speechMs: (json['speechMs'] as num?)?.toInt() ?? 0,
        degraded: json['degraded'] == true,
        mismatch: json['mismatch'] == true,
        words: (json['words'] as List? ?? const [])
            .whereType<Map>()
            .map(ShadowWord.fromJson)
            .toList(),
        missedWords:
            (json['missedWords'] as List? ?? const []).map((e) => '$e').toList(),
        insertions: (json['insertions'] as num?)?.toInt() ?? 0,
        per: (json['per'] as num?)?.toDouble() ?? 0,
        unmappedPhones: (json['unmappedPhones'] as List? ?? const [])
            .map((e) => '$e')
            .toList(),
      );

  /// 交给 JS 引擎的形状。游戏逻辑在 typing/service/shadow/shadow.ts 里。
  Map<String, dynamic> toJson() => {
        'overall': overall,
        'accuracy': accuracy,
        'completeness': completeness,
        'fluency': fluency,
        'durationMs': durationMs,
        'speechMs': speechMs,
        'degraded': degraded,
        'mismatch': mismatch,
        'words': words.map((e) => e.toJson()).toList(),
        'missedWords': missedWords,
        'insertions': insertions,
        'per': per,
        'unmappedPhones': unmappedPhones,
      };
}

/// /v1/health 的返回。
class ShadowHealth {
  final int latencyMs;
  final int proto;
  final bool modelInstalled;

  /// 和 modelInstalled 分开：模型 1.26 GB，"服务在但还在加载"是个常见状态，
  /// 设置页的"测试连接"要能说清是哪一种。
  final bool modelLoaded;
  final bool g2pOk;
  final String device;
  final String lang;
  final String error;

  const ShadowHealth({
    required this.latencyMs,
    this.proto = 0,
    this.modelInstalled = false,
    this.modelLoaded = false,
    this.g2pOk = false,
    this.device = '',
    this.lang = '',
    this.error = '',
  });

  /// 能不能真的打分。
  bool get ready => modelInstalled && g2pOk;

  Map<String, dynamic> toJson() => {
        'latencyMs': latencyMs,
        'proto': proto,
        'modelInstalled': modelInstalled,
        'modelLoaded': modelLoaded,
        'g2pOk': g2pOk,
        'device': device,
        'lang': lang,
        'error': error,
        'ready': ready,
      };
}

/// 模型安装状态 / 下载进度。
class ShadowModelState {
  final bool installed;
  final int onDisk;
  final int size;
  final String state;
  final int done;
  final int total;
  final String file;
  final String error;

  const ShadowModelState({
    this.installed = false,
    this.onDisk = 0,
    this.size = 0,
    this.state = 'idle',
    this.done = 0,
    this.total = 0,
    this.file = '',
    this.error = '',
  });
}

/// 跟读打分服务的客户端。
///
/// 服务端见仓库 server/shadow，协议见 server/shadow/PROTOCOL.md。
/// 和 [AiRemote]（8765）是两个独立服务，完全可能只开其中一个。
///
/// 复用 AiRemote 的 [AiRemoteDown] / [AiRemoteRejected]：
/// "服务挂了该回退"和"服务明确拒绝、回退也没用"的区分在这边一模一样。
class ShadowRemote {
  static const int defaultPort = 8766;
  static const String urlHint = 'http://192.168.1.2:8766';

  static Future<String> url() async =>
      (await Db().db.kvDao.getStr(K.shadowRemoteUrl)) ?? '';

  static Future<void> setUrl(String v) async {
    await Db().db.kvDao.insertOrReplace(Kv(K.shadowRemoteUrl, normalize(v)));
  }

  /// 开关打开**且**地址非空才算启用。
  static Future<bool> enabled() async {
    if ((await Db().db.kvDao.getStr(K.shadowRemoteEnabled)) != '1') {
      return false;
    }
    return (await url()).isNotEmpty;
  }

  static Future<bool> switchOn() async =>
      (await Db().db.kvDao.getStr(K.shadowRemoteEnabled)) == '1';

  static Future<void> setEnabled(bool v) async {
    await Db().db.kvDao.insertOrReplace(Kv(K.shadowRemoteEnabled, v ? '1' : '0'));
  }

  /// 复用 AiRemote 的实现，只把默认端口换成 8766。
  /// 那里面关于 Uri.hasPort 的坑，自己再写一遍就会重踩一次。
  static String normalize(String raw) =>
      AiRemote.normalize(raw, port: defaultPort);

  static Dio _dio(String baseUrl, {Duration? timeout}) {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: timeout ?? const Duration(seconds: 30),
      sendTimeout: timeout ?? const Duration(seconds: 30),
      validateStatus: (_) => true,
    ));
  }

  static Never _fail(Object e) {
    if (e is AiRemoteDown || e is AiRemoteRejected) {
      throw e;
    }
    throw AiRemoteDown('$e');
  }

  /// 4xx -> Rejected（别回退），5xx/其它 -> Down（可以回退）。
  static void _check(Response<dynamic> resp) {
    final code = resp.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      return;
    }
    final data = resp.data;
    var msg = 'HTTP $code';
    if (data is Map && data['error'] != null) {
      msg = '${data['error']}';
    }
    if (code >= 400 && code < 500) {
      throw AiRemoteRejected(msg);
    }
    throw AiRemoteDown(msg);
  }

  /// 探活。顺便量往返延迟，设置页的"测试连接"显示它。
  static Future<ShadowHealth> health(String baseUrl) async {
    final start = DateTime.now();
    try {
      final resp = await _dio(baseUrl, timeout: const Duration(seconds: 5))
          .get<dynamic>('/v1/health');
      _check(resp);
      final data = resp.data;
      if (data is! Map) {
        throw const AiRemoteDown('bad health response');
      }
      final g2p = data['g2p'];
      return ShadowHealth(
        latencyMs: DateTime.now().difference(start).inMilliseconds,
        proto: (data['proto'] as num?)?.toInt() ?? 0,
        modelInstalled: data['modelInstalled'] == true,
        modelLoaded: data['modelLoaded'] == true,
        g2pOk: g2p is Map && g2p['ok'] == true,
        device: '${data['device'] ?? ''}',
        lang: g2p is Map ? '${g2p['lang'] ?? ''}' : '',
        error: g2p is Map ? '${g2p['error'] ?? ''}' : '',
      );
    } catch (e) {
      _fail(e);
    }
  }

  /// 打一次分。[wav] 必须是 16k 单声道 PCM16。
  ///
  /// 60 秒的接收超时：CPU 上一句话的前向大约 0.8~1.5 秒，模型冷加载再加几秒，
  /// 留足余量。真连不上的话 5 秒的 connectTimeout 会先兜住。
  static Future<ShadowScore> score(
    String baseUrl, {
    required Uint8List wav,
    required String text,
    String lang = '',
    Map<String, dynamic>? params,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      final form = FormData.fromMap({
        'text': text,
        if (lang.isNotEmpty) 'lang': lang,
        if (params != null) 'params': jsonEncode(params),
        'audio': MultipartFile.fromBytes(wav, filename: 'a.wav'),
      });
      final resp = await _dio(baseUrl, timeout: timeout)
          .post<dynamic>('/v1/score', data: form);
      _check(resp);
      final data = resp.data;
      if (data is! Map) {
        throw const AiRemoteDown('bad score response');
      }
      return ShadowScore.fromJson(data);
    } catch (e) {
      _fail(e);
    }
  }

  static Future<ShadowModelState> modelState(String baseUrl) async {
    try {
      final dio = _dio(baseUrl, timeout: const Duration(seconds: 10));
      final m = await dio.get<dynamic>('/v1/model');
      _check(m);
      final d = await dio.get<dynamic>('/v1/model/download');
      _check(d);
      final mm = m.data is Map ? m.data as Map : const {};
      final dd = d.data is Map ? d.data as Map : const {};
      return ShadowModelState(
        installed: mm['installed'] == true,
        onDisk: (mm['onDisk'] as num?)?.toInt() ?? 0,
        size: (mm['size'] as num?)?.toInt() ?? 0,
        state: '${dd['state'] ?? 'idle'}',
        done: (dd['done'] as num?)?.toInt() ?? 0,
        total: (dd['total'] as num?)?.toInt() ?? 0,
        file: '${dd['file'] ?? ''}',
        error: '${dd['error'] ?? ''}',
      );
    } catch (e) {
      _fail(e);
    }
  }

  /// 让服务端自己去下模型。1.26 GB，不是手机上传——手机上不会有这个模型。
  static Future<void> startDownload(String baseUrl) async {
    try {
      final resp = await _dio(baseUrl, timeout: const Duration(seconds: 10))
          .post<dynamic>('/v1/model/download');
      _check(resp);
    } catch (e) {
      _fail(e);
    }
  }

  static Future<void> cancelDownload(String baseUrl) async {
    try {
      final resp = await _dio(baseUrl, timeout: const Duration(seconds: 10))
          .post<dynamic>('/v1/model/cancel');
      _check(resp);
    } catch (e) {
      _fail(e);
    }
  }
}
