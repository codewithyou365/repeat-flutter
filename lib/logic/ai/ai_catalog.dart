import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';

/// 一个模型在流水线里承担的角色。
///
/// 名字会被存进 Kv（K.aiVadModelId 等只存 id，角色本身是代码里的枚举），
/// 也会出现在 catalog.json 的 "role" 字段里，所以不能随便改名。
enum AiRole {
  /// 判停：silero，决定一句话在哪儿切开
  vad,

  /// 识别：把音频转成原文
  asr,

  /// 翻译：把原文转成译文。whisper 用 task=translate 时同时兼任 asr 和 mt
  mt,

  /// 合成：神经网络语音模型把译文读出来（不是系统 TTS 引擎）
  tts,
}

extension AiRoleLabel on AiRole {
  /// 角色的显示名。放这儿而不是各页面各写一份，是因为"缺哪个角色的模型"这句提示
  /// 在选择框和设置页都要用。
  String get label {
    switch (this) {
      case AiRole.vad:
        return I18nKey.aiRoleVad.tr;
      case AiRole.asr:
        return I18nKey.aiRoleAsr.tr;
      case AiRole.mt:
        return I18nKey.aiRoleMt.tr;
      case AiRole.tts:
        return I18nKey.aiRoleTts.tr;
    }
  }
}

/// 模型目录里的一个文件。
///
/// 一个"模型"几乎从来不是一个文件：whisper 要 encoder+decoder+tokens，
/// kokoro 还要 voices.bin、lexicon、jieba 词典和整个 espeak-ng-data 目录。
/// 所以清单从一开始就是按文件列表建模的。
class AiModelFile {
  /// 相对模型目录的路径，可以带子目录，比如 "espeak-ng-data/phontab"
  final String path;
  final String url;
  final String hash;
  final int size;

  const AiModelFile({required this.path, required this.url, required this.hash, required this.size});

  static AiModelFile? fromJson(Map<String, dynamic> json) {
    final path = json['p'] as String? ?? '';
    final url = json['u'] as String? ?? '';
    if (path.isEmpty || url.isEmpty) {
      return null;
    }
    return AiModelFile(
      path: path,
      url: url,
      hash: json['h'] as String? ?? '',
      size: (json['s'] as num?)?.toInt() ?? 0,
    );
  }
}

class AiModelEntry {
  final String id;
  final List<AiRole> roles;
  final String name;

  /// 支持的语言，["*"] 表示不限
  final List<String> langs;

  /// 只对 mt 角色有意义：能翻译到哪些目标语言。whisper 的 translate 任务只能到 en。
  final List<String> mtTargets;

  final int size;

  /// 说话人（音色）数量。只有 tts 角色有意义，1 表示这个模型只有一个声音。
  final int speakers;

  /// 音色名，下标就是传给 sherpa 的 speaker id。空表示这个模型没给名字，
  /// 界面上只能退回 "#0 #1" 这种编号。**顺序不能动**：改了等于把用户存的音色偷换成另一个人。
  final List<String> voices;

  final String license;
  final String note;

  /// files 和 zip 二选一。文件多的模型（kokoro 带 espeak-ng-data）用 zip，
  /// 少数几个文件的（whisper/sensevoice/silero）用 files 直接列。
  final List<AiModelFile> files;
  final AiModelFile? zip;

  /// 原样透传给 sherpa_onnx 的 config。sherpa 的 config 树整棵都有 fromJson，
  /// 所以这里不做任何映射，推理侧直接反序列化，也天然能跨 isolate 传。
  final Map<String, dynamic> cfg;

  const AiModelEntry({
    required this.id,
    required this.roles,
    required this.name,
    required this.langs,
    required this.mtTargets,
    required this.size,
    required this.speakers,
    required this.voices,
    required this.license,
    required this.note,
    required this.files,
    required this.zip,
    required this.cfg,
  });

  bool hasRole(AiRole role) => roles.contains(role);

  /// 压缩包的扩展名。sherpa 官方发布的模型全是 tar.bz2，只有个别是 zip。
  static String _archiveExt(String url) {
    final lower = url.toLowerCase();
    for (final ext in ['.tar.bz2', '.tbz', '.tar.gz', '.tgz', '.tar.xz', '.txz', '.tar', '.zip']) {
      if (lower.endsWith(ext)) {
        return ext;
      }
    }
    return '.zip';
  }

  /// 下载单位：zip 形式就是一个条目，files 形式就是每个文件一条。
  List<AiModelFile> get downloadUnits => zip != null ? [zip!] : files;

  static AiModelEntry? fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    if (id.isEmpty) {
      return null;
    }

    // role 允许是字符串或字符串数组：一份 whisper 同时满足 asr 和 mt。
    final rawRole = json['role'];
    final roleNames = <String>[
      if (rawRole is String) rawRole,
      if (rawRole is List) ...rawRole.whereType<String>(),
    ];
    final roles = <AiRole>[];
    for (final n in roleNames) {
      // 清单是数据、可能来自远程，遇到本版本不认识的角色跳过而不是抛异常。
      final r = AiRole.values.where((e) => e.name == n).firstOrNull;
      if (r != null && !roles.contains(r)) {
        roles.add(r);
      }
    }
    if (roles.isEmpty) {
      return null;
    }

    final files = <AiModelFile>[];
    final rawFiles = json['files'];
    if (rawFiles is List) {
      for (final f in rawFiles) {
        if (f is Map<String, dynamic>) {
          final mf = AiModelFile.fromJson(f);
          if (mf != null) files.add(mf);
        }
      }
    }

    AiModelFile? zip;
    final rawZip = json['zip'];
    if (rawZip is Map<String, dynamic>) {
      // 压缩包落地时的文件名用 id 命名，避免依赖 url 的最后一段；
      // **但扩展名必须照抄**——解压那一步是按扩展名分派的（见 AiModelHelp._extract）。
      zip = AiModelFile(
        path: '$id${_archiveExt(rawZip['u'] as String? ?? '')}',
        url: rawZip['u'] as String? ?? '',
        hash: rawZip['h'] as String? ?? '',
        size: (rawZip['s'] as num?)?.toInt() ?? 0,
      );
      if (zip.url.isEmpty) zip = null;
    }

    if (files.isEmpty && zip == null) {
      return null;
    }

    final voices = (json['voices'] as List?)?.whereType<String>().toList() ?? const <String>[];

    return AiModelEntry(
      id: id,
      roles: roles,
      name: json['name'] as String? ?? id,
      langs: (json['langs'] as List?)?.whereType<String>().toList() ?? const ['*'],
      mtTargets: (json['mtTargets'] as List?)?.whereType<String>().toList() ?? const [],
      size: (json['size'] as num?)?.toInt() ?? files.fold<int>(0, (a, b) => a + b.size) + (zip?.size ?? 0),
      speakers: (json['speakers'] as num?)?.toInt() ?? (voices.isEmpty ? 1 : voices.length),
      voices: voices,
      license: json['license'] as String? ?? '',
      note: json['note'] as String? ?? '',
      files: files,
      zip: zip,
      cfg: (json['cfg'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

class AiPreset {
  final String id;
  final String name;
  final List<String> modelIds;

  const AiPreset({required this.id, required this.name, required this.modelIds});

  static AiPreset? fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final ids = (json['models'] as List?)?.whereType<String>().toList() ?? const [];
    if (id.isEmpty || ids.isEmpty) {
      return null;
    }
    return AiPreset(id: id, name: json['name'] as String? ?? id, modelIds: ids);
  }
}

class AiCatalog {
  final int version;
  final List<AiModelEntry> models;
  final List<AiPreset> presets;

  const AiCatalog({required this.version, required this.models, required this.presets});

  static const AiCatalog empty = AiCatalog(version: 0, models: [], presets: []);

  AiModelEntry? byId(String id) => models.where((e) => e.id == id).firstOrNull;

  List<AiModelEntry> byRole(AiRole role) => models.where((e) => e.hasRole(role)).toList();

  static const String assetPath = 'assets/ai/catalog.json';

  static AiCatalog? _cache;

  /// 内置清单 + 可选的远程覆盖。
  ///
  /// 远程只是"覆盖"：同 id 顶掉内置的，其余取并集。任何一步失败都静默回落到内置清单——
  /// 拉不到远程绝不能让整个功能不可用。
  static Future<AiCatalog> load({bool refresh = false}) async {
    if (!refresh && _cache != null) {
      return _cache!;
    }
    var catalog = await _loadAsset();
    final url = (await Db().db.kvDao.getStr(K.aiCatalogUrl)) ?? '';
    if (url.isNotEmpty) {
      final remote = await _fetchRemote(url);
      if (remote != null) {
        catalog = _merge(catalog, remote);
      }
    }
    _cache = catalog;
    return catalog;
  }

  static Future<AiCatalog> _loadAsset() async {
    try {
      return _parse(jsonDecode(await rootBundle.loadString(assetPath)));
    } catch (e) {
      debugPrint('AiCatalog._loadAsset failed: $e');
      return empty;
    }
  }

  static Future<AiCatalog?> _fetchRemote(String url) async {
    for (final skipSsl in [false, true]) {
      try {
        var dio = Dio();
        if (skipSsl) {
          dio = Dio()
            ..httpClientAdapter = IOHttpClientAdapter(createHttpClient: () {
              final client = HttpClient();
              client.badCertificateCallback = (_, _, _) => true;
              return client;
            });
        }
        final resp = await dio.get<String>(url,
            options: Options(
              responseType: ResponseType.plain,
              headers: {HttpHeaders.userAgentHeader: DownloadConstant.userAgent},
            ));
        final body = resp.data;
        if (body == null || body.isEmpty) {
          return null;
        }
        return _parse(jsonDecode(body));
      } catch (e) {
        // 自签证书的第一遍会失败，第二遍 skipSsl 再试一次；两遍都挂就放弃。
        if (skipSsl || !e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
          debugPrint('AiCatalog._fetchRemote failed: $e');
          return null;
        }
      }
    }
    return null;
  }

  static AiCatalog _merge(AiCatalog base, AiCatalog override) {
    final models = <String, AiModelEntry>{for (final m in base.models) m.id: m};
    for (final m in override.models) {
      models[m.id] = m;
    }
    final presets = <String, AiPreset>{for (final p in base.presets) p.id: p};
    for (final p in override.presets) {
      presets[p.id] = p;
    }
    return AiCatalog(
      version: override.version,
      models: models.values.toList(),
      presets: presets.values.toList(),
    );
  }

  static AiCatalog _parse(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) {
      return empty;
    }
    final models = <AiModelEntry>[];
    final rawModels = decoded['models'];
    if (rawModels is List) {
      for (final m in rawModels) {
        if (m is Map<String, dynamic>) {
          final e = AiModelEntry.fromJson(m);
          if (e != null) models.add(e);
        }
      }
    }
    final presets = <AiPreset>[];
    final rawPresets = decoded['presets'];
    if (rawPresets is List) {
      for (final p in rawPresets) {
        if (p is Map<String, dynamic>) {
          final e = AiPreset.fromJson(p);
          if (e != null) presets.add(e);
        }
      }
    }
    return AiCatalog(version: (decoded['v'] as num?)?.toInt() ?? 0, models: models, presets: presets);
  }
}
