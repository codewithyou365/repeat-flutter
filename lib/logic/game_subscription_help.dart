import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/classroom_help.dart';
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/game_manifest.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

/// 游戏订阅的网络侧：抓 manifest、下载并落地 zip。
///
/// 这里只管把包弄下来，不碰 [Classroom.content]——那部分在 GameListLogic 里，
/// 因为课堂内容的读写、'd' 的引用计数都在那边。
class GameSubscriptionHelp {
  /// GET manifest.json 并解析。
  ///
  /// 拿不到、不是合法 JSON、或者解析不出任何游戏入口，都返回 null（并弹 Snackbar），
  /// 调用方一律当「这不是个订阅地址」处理。
  static Future<GameManifest?> fetchManifest(String url) async {
    url = url.trim();
    if (url.isEmpty) return null;
    var manifest = await _fetchManifest(url, false);
    if (manifest == null && _lastNeedSkipSsl) {
      // 自签名证书：跟 DownloadDoc 一样，放行一次重试。
      manifest = await _fetchManifest(url, true);
    }
    return manifest;
  }

  /// [fetchManifest] 上一次失败是不是因为自签名证书。
  static bool _lastNeedSkipSsl = false;

  static Future<GameManifest?> _fetchManifest(String url, bool skipSsl) async {
    _lastNeedSkipSsl = false;
    var dio = Dio();
    if (skipSsl) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
          return client;
        },
      );
    }
    try {
      final resp = await dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {HttpHeaders.userAgentHeader: DownloadConstant.userAgent},
        ),
      );
      final body = resp.data;
      if (body == null || body.isEmpty) {
        Snackbar.show(I18nKey.gameManifestInvalid.tr);
        return null;
      }
      final manifest = GameManifest.fromJsonOrNull(jsonDecode(body));
      if (manifest == null) {
        Snackbar.show(I18nKey.gameManifestInvalid.tr);
      }
      return manifest;
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('CERTIFICATE_VERIFY_FAILED: self signed certificate')) {
        _lastNeedSkipSsl = true;
        return null;
      }
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs([msg]));
      return null;
    } catch (e) {
      // jsonDecode 抛的是 FormatException，不是 Exception 的子类以外的东西也可能来，兜住。
      Snackbar.show(I18nKey.gameManifestInvalid.tr);
      return null;
    }
  }

  /// 下载 [manifest] 指定的 zip，校验 sha1，落到课堂的文件目录并解压。
  ///
  /// 返回落地后的 [DownloadContent]（调用方拿它去写课堂的 'd'），失败返回 null。
  /// 同 hash 的包已经在磁盘上就直接复用，不重复下载。
  static Future<DownloadContent?> download(
    int classroomId,
    String manifestUrl,
    GameManifest manifest,
  ) async {
    if (manifest.zip.isEmpty) {
      Snackbar.show(I18nKey.gameManifestInvalid.tr);
      return null;
    }
    if (manifest.hash.isEmpty) {
      // 没 hash 就没法定位落地路径（文件名就是 hash），也没法校验，直接拒。
      Snackbar.show(I18nKey.gameManifestInvalid.tr);
      return null;
    }

    // 服务器注入的 'zip' 是相对 manifest 的地址（go 服务器给的就是 'typing.zip'），
    // 必须相对 manifest 的 URL 解析，不能当绝对地址用。
    final Uri zipUri;
    try {
      zipUri = Uri.parse(manifestUrl).resolve(manifest.zip);
    } catch (e) {
      Snackbar.show(I18nKey.gameManifestInvalid.tr);
      return null;
    }
    final zipName = zipUri.pathSegments.isEmpty ? 'game.zip' : zipUri.pathSegments.last;

    final dc = DownloadContent(url: zipName, hash: manifest.hash);
    final rootPath = await DocPath.getContentPath();
    final resPath = rootPath.joinPath(DocPath.getFilesRelativePathOf(classroomId));
    final zipPath = resPath.joinPath(dc.path);
    final destPath = resPath.joinPath(dc.folder).joinPath(dc.pureName);

    await Folder.ensureExists(resPath.joinPath(dc.folder));

    // hash 参数只是「已存在且匹配就跳过下载」的前置检查，不校验下载回来的字节。
    var result = await DownloadDoc.start(zipUri.toString(), zipPath, hash: manifest.hash);
    if (result == DownloadDocResult.needSkipSsl) {
      result = await DownloadDoc.start(zipUri.toString(), zipPath, hash: manifest.hash, skipSsl: true);
    }
    if (result != DownloadDocResult.success) {
      return null;
    }

    // 所以这里必须自己再算一次。
    final actual = await Hash.toSha1(zipPath);
    if (actual != manifest.hash) {
      debugPrint('game subscription hash mismatch: want ${manifest.hash}, got $actual');
      await _deleteQuietly(zipPath);
      Snackbar.show(I18nKey.gameHashMismatch.tr);
      return null;
    }

    final ok = await ClassroomHelp.unzipGame(zipPath, destPath);
    if (!ok) {
      // 解压不了就不留垃圾：这个 zip 还没写进 'd'，没人会再引用它。
      await _deleteQuietly(zipPath);
      await Folder.delete(destPath);
      Snackbar.show(I18nKey.gameUnzipFailed.tr);
      return null;
    }
    return dc;
  }

  static Future<void> _deleteQuietly(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } on FileSystemException catch (_) {}
  }
}
