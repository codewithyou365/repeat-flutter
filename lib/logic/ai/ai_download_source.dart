import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';

/// 模型下载源。
///
/// 清单里存的一律是官方地址（huggingface.co / github.com），下载和展示的时候
/// 才按这里改写。这样换源不用动清单，也不用重新下载已经装好的模型。
///
/// 名字会存进 Kv，只能往后加不能改名。
enum AiDownloadSource {
  /// 官方源，原样不动
  official,

  /// 国内镜像：HuggingFace 走 hf-mirror.com，GitHub release 走加速前缀。
  /// 实测两边返回的 content-length 跟官方逐字节一致。
  cn,

  /// 用户自填
  custom,
}

class AiDownloadSourceHelp {
  static const String hfHost = 'huggingface.co';
  static const String cnHfHost = 'hf-mirror.com';

  /// GitHub 的加速前缀是"前缀 + 完整原 url"的形式，不是替换主机。
  static const String cnGhPrefix = 'https://ghfast.top/';

  static Future<AiDownloadSource> current() async {
    final v = await Db().db.kvDao.getStr(K.aiDownloadSource);
    return AiDownloadSource.values.where((e) => e.name == v).firstOrNull ?? AiDownloadSource.official;
  }

  static Future<void> set(AiDownloadSource source) async {
    await Db().db.kvDao.insertOrReplace(Kv(K.aiDownloadSource, source.name));
  }

  static Future<String> customHfHost() async =>
      (await Db().db.kvDao.getStr(K.aiCustomHfHost))?.trim() ?? '';

  static Future<String> customGhPrefix() async =>
      (await Db().db.kvDao.getStr(K.aiCustomGhPrefix))?.trim() ?? '';

  /// 一次性把改写需要的参数取出来，省得每个文件都查一遍库。
  static Future<AiUrlRewriter> rewriter() async {
    final source = await current();
    switch (source) {
      case AiDownloadSource.official:
        return const AiUrlRewriter(hfHost: '', ghPrefix: '');
      case AiDownloadSource.cn:
        return const AiUrlRewriter(hfHost: cnHfHost, ghPrefix: cnGhPrefix);
      case AiDownloadSource.custom:
        return AiUrlRewriter(hfHost: await customHfHost(), ghPrefix: await customGhPrefix());
    }
  }
}

class AiUrlRewriter {
  /// 替换 huggingface.co 的主机名。空则不换。
  final String hfHost;

  /// 加在 github.com 地址前面的加速前缀。空则不加。
  final String ghPrefix;

  const AiUrlRewriter({required this.hfHost, required this.ghPrefix});

  bool get isIdentity => hfHost.isEmpty && ghPrefix.isEmpty;

  String call(String url) {
    if (hfHost.isNotEmpty && url.contains('://${AiDownloadSourceHelp.hfHost}/')) {
      return url.replaceFirst('://${AiDownloadSourceHelp.hfHost}/', '://$hfHost/');
    }
    if (ghPrefix.isNotEmpty && (url.contains('://github.com/') || url.contains('://objects.githubusercontent.com/'))) {
      // 已经带过前缀就别再套一层
      if (url.startsWith(ghPrefix)) {
        return url;
      }
      return '${ghPrefix.endsWith('/') ? ghPrefix : '$ghPrefix/'}$url';
    }
    return url;
  }
}
