import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/zip.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
import 'package:repeat_flutter/logic/ai/ai_download_source.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/download.dart';

/// 模型安装进度。fileIndex/fileTotal 是"第几个文件"，bytes* 是当前这个文件的字节数。
typedef AiInstallProgress = void Function(int fileIndex, int fileTotal, int bytesCount, int bytesTotal);

enum AiInstallResult { success, fail, cancelled }

/// AI 模型的安装/卸载/选中状态。
///
/// 磁盘布局（`<databasesPath>/m`，是 content 的兄弟目录，理由见 [DocPath.model]）：
///
///     m/<modelId>/        解压后的模型目录，保持上游布局
///     m/<modelId>/.ok     全部文件 sha1 校验通过后才写；有它才算装好
///     m/.tmp/             下载暂存，安装成功或失败都会清掉
class AiModelHelp {
  /// 装好的标记文件。半个模型目录不能被当成装好了，否则加载时才崩。
  static const String okMarker = '.ok';
  static const String tmpDir = '.tmp';

  static Future<String> rootPath() async => await DocPath.getModelPath();

  static Future<String> dirOf(String modelId) async => (await rootPath()).joinPath(modelId);

  static Future<bool> isInstalled(String modelId) async {
    return await File((await dirOf(modelId)).joinPath(okMarker)).exists();
  }

  /// 模型目录占的字节数。目录不存在返回 0。
  static Future<int> sizeOnDisk(String modelId) async {
    return await _dirSize(await dirOf(modelId));
  }

  /// m/ 整个目录占的字节数，设置页顶部显示用。
  static Future<int> totalSizeOnDisk() async => await _dirSize(await rootPath());

  static Future<int> _dirSize(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      return 0;
    }
    var total = 0;
    try {
      await for (final e in dir.list(recursive: true, followLinks: false)) {
        if (e is File) {
          total += await e.length();
        }
      }
    } catch (e) {
      debugPrint('AiModelHelp._dirSize failed: $e');
    }
    return total;
  }

  /// 启动时清一次下载暂存。上次装到一半被杀掉的残留没有任何用。
  static Future<void> cleanTemp() async {
    await Folder.delete((await rootPath()).joinPath(tmpDir));
  }

  // ---------------------------------------------------------------- 角色选中

  static K _kOf(AiRole role) {
    switch (role) {
      case AiRole.vad:
        return K.aiVadModelId;
      case AiRole.asr:
        return K.aiAsrModelId;
      case AiRole.mt:
        return K.aiMtModelId;
      case AiRole.tts:
        return K.aiTtsModelId;
    }
  }

  /// 某个角色当前实际能用的模型。
  ///
  /// 存的 id 可能已经被删掉或者已经不在清单里（换了远程清单），这时不认死那条记录，
  /// 退回到"任意一个装好了且能担这个角色的模型"。都没有才返回 null。
  static Future<AiModelEntry?> selectedFor(AiRole role, AiCatalog catalog) async {
    final id = (await Db().db.kvDao.getStr(_kOf(role))) ?? '';
    if (id.isNotEmpty) {
      final entry = catalog.byId(id);
      if (entry != null && entry.hasRole(role) && await isInstalled(id)) {
        return entry;
      }
    }
    for (final e in catalog.byRole(role)) {
      if (await isInstalled(e.id)) {
        return e;
      }
    }
    return null;
  }

  static Future<void> select(AiRole role, String modelId) async {
    await Db().db.kvDao.insertOrReplace(Kv(_kOf(role), modelId));
  }

  /// 还缺哪些角色的模型。空列表表示可以开录了。
  static Future<List<AiRole>> missingRoles(AiCatalog catalog) async {
    final missing = <AiRole>[];
    for (final role in AiRole.values) {
      if (await selectedFor(role, catalog) == null) {
        missing.add(role);
      }
    }
    return missing;
  }

  // ---------------------------------------------------------------- 安装

  /// 装一个模型。**严格串行下载每个文件**。
  ///
  /// 为什么不能并发：[DownloadDoc.start] 的临时文件是固定路径 `<content>/temp`，
  /// 两个下载同时跑会互相覆盖，最后 rename 出来的内容是错的而且不报错。
  ///
  /// 另外也不能给 [DownloadDoc.start] 传绝对目标路径：传绝对路径时它会
  /// `ensureExists(contentRoot + 绝对路径)`，造出一棵垃圾目录树，而真正的父目录没建，
  /// 最后 rename 抛异常。所以这里一律下到 content 下的相对暂存路径，自己 rename 过去。
  static Future<AiInstallResult> install(
    AiModelEntry entry, {
    AiInstallProgress? onProgress,
    bool Function()? isCancelled,
  }) async {
    final dir = await dirOf(entry.id);
    final okPath = dir.joinPath(okMarker);
    // 重装先把标记清掉：中途失败时目录里是半成品，绝不能还留着 .ok。
    await _deleteQuietly(okPath);
    await Folder.ensureExists(dir);

    final units = entry.downloadUnits;
    final rewrite = await AiDownloadSourceHelp.rewriter();
    final contentRoot = await DocPath.getContentPath();
    final relTmpDir = '.ai_tmp';
    await Folder.ensureExists(contentRoot.joinPath(relTmpDir));

    try {
      for (var i = 0; i < units.length; i++) {
        if (isCancelled?.call() == true) {
          await _cleanFailed(entry.id);
          return AiInstallResult.cancelled;
        }
        final unit = units[i];
        final targetPath = dir.joinPath(unit.path);

        // 断点续传：已经就位且校验得过的文件直接跳过，重装/续装不用重下几百 MB。
        if (await _verify(targetPath, unit)) {
          onProgress?.call(i + 1, units.length, unit.size, unit.size);
          continue;
        }

        final relTmp = '$relTmpDir/${entry.id}_$i';
        final absTmp = contentRoot.joinPath(relTmp);
        await _deleteQuietly(absTmp);

        // 清单里存的是官方地址，这里按用户选的下载源改写（国内直连 HuggingFace/GitHub
        // 基本下不动，换成镜像才走得通）。改写只影响这一次下载，不写回清单。
        final url = rewrite(unit.url);
        var result = await DownloadDoc.start(
          url,
          relTmp,
          progressCallback: (_, count, total, _) => onProgress?.call(i + 1, units.length, count, total),
        );
        if (result == DownloadDocResult.needSkipSsl) {
          result = await DownloadDoc.start(
            url,
            relTmp,
            skipSsl: true,
            progressCallback: (_, count, total, _) => onProgress?.call(i + 1, units.length, count, total),
          );
        }
        if (result != DownloadDocResult.success) {
          await _cleanFailed(entry.id);
          return AiInstallResult.fail;
        }

        // DownloadDoc 的 hash 参数只是"下载前的预检"，下完必须自己再校验一次。
        if (!await _verify(absTmp, unit)) {
          debugPrint('AiModelHelp.install verify failed for ${unit.path}');
          await _deleteQuietly(absTmp);
          await _cleanFailed(entry.id);
          return AiInstallResult.fail;
        }

        await Folder.ensureExists(File(targetPath).parent.path);
        await _deleteQuietly(targetPath);
        await File(absTmp).rename(targetPath);
      }

      if (entry.zip != null) {
        final zipPath = dir.joinPath(entry.zip!.path);
        await _extract(zipPath, dir);
        await _deleteQuietly(zipPath);
        // 上游压缩包一般带一层同名顶层目录，展开后把它拍平，
        // 这样 cfg 里的路径就不用关心打包的人有没有带这层目录。
        await _flattenSingleRoot(dir);
      }

      await File(okPath).writeAsString(entry.id);
      return AiInstallResult.success;
    } catch (e) {
      debugPrint('AiModelHelp.install failed: $e');
      await _cleanFailed(entry.id);
      return AiInstallResult.fail;
    } finally {
      await Folder.delete(contentRoot.joinPath(relTmpDir));
    }
  }

  // ---------------------------------------------------------------- 手动导入

  /// 这个模型还缺哪些文件（不存在或校验不过的）。
  ///
  /// 手动导入时用来告诉用户"还差几个"，也用来决定能不能写 .ok。
  static Future<List<AiModelFile>> missingFiles(AiModelEntry entry) async {
    final dir = await dirOf(entry.id);
    final out = <AiModelFile>[];
    for (final f in entry.files) {
      if (!await _verify(dir.joinPath(f.path), f)) {
        out.add(f);
      }
    }
    return out;
  }

  /// 按当前下载源改写过的下载地址，给用户自己去下载用。
  ///
  /// 国内直连 HuggingFace/GitHub 经常下不动，除了在应用里换镜像，还得允许用户
  /// 拿着地址在别的设备/别的网络下好，再从本地导进来。
  static Future<List<String>> downloadUrls(AiModelEntry entry) async {
    final rewrite = await AiDownloadSourceHelp.rewriter();
    return entry.downloadUnits.map((e) => rewrite(e.url)).toList();
  }

  /// 从用户挑的本地文件安装。
  ///
  /// 两种形态都认：
  /// - 挑一个 .zip：当成整个模型目录的压缩包解开（多余的顶层目录会被拍平）
  /// - 挑若干个散文件：**按文件名**匹配到清单条目。清单里每个模型的文件名都是唯一的
  ///   （连 melo-tts 那 16 个带子目录的也是），所以文件名足够定位，用户不用还原目录结构。
  ///
  /// 允许分几次导入：每次只把认得的文件放进去，等全部齐了才写 .ok。
  static Future<AiInstallResult> importFromPaths(AiModelEntry entry, List<String> paths) async {
    if (paths.isEmpty) {
      return AiInstallResult.fail;
    }
    final dir = await dirOf(entry.id);
    final okPath = dir.joinPath(okMarker);
    await _deleteQuietly(okPath);
    await Folder.ensureExists(dir);

    try {
      if (paths.length == 1 && _isArchive(paths.first)) {
        await _extract(paths.first, dir);
        await _flattenSingleRoot(dir);
      } else {
        // 文件名 -> 清单条目。zip 形式的模型没有 files 列表，这时按 zip 那一项匹配。
        final wanted = <String, AiModelFile>{};
        for (final f in entry.downloadUnits) {
          wanted[f.path.split('/').last.toLowerCase()] = f;
        }
        for (final p in paths) {
          final name = p.split(Platform.pathSeparator).last.toLowerCase();
          final target = wanted[name];
          if (target == null) {
            // 挑错文件不算失败，只是忽略——用户一次多选了别的模型的文件很正常
            debugPrint('AiModelHelp.importFromPaths: 忽略不认识的文件 $name');
            continue;
          }
          final targetPath = dir.joinPath(target.path);
          await Folder.ensureExists(File(targetPath).parent.path);
          await _deleteQuietly(targetPath);
          await File(p).copy(targetPath);
        }
        // 导进来的如果是 zip 形式那一项，解开它
        if (entry.zip != null) {
          final zipPath = dir.joinPath(entry.zip!.path);
          if (await File(zipPath).exists()) {
            await _extract(zipPath, dir);
            await _deleteQuietly(zipPath);
            await _flattenSingleRoot(dir);
          }
        }
      }

      final missing = await missingFiles(entry);
      if (missing.isNotEmpty) {
        // 不删目录：这次导进来的留着，用户可以接着补剩下的。
        // 但绝不写 .ok——半个模型被当成装好了，只会在加载时才炸。
        debugPrint('AiModelHelp.importFromPaths: 还缺 ${missing.length} 个文件');
        return AiInstallResult.fail;
      }
      await File(okPath).writeAsString(entry.id);
      return AiInstallResult.success;
    } catch (e) {
      debugPrint('AiModelHelp.importFromPaths failed: $e');
      return AiInstallResult.fail;
    }
  }

  static bool _isArchive(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.zip') ||
        lower.endsWith('.tar.bz2') ||
        lower.endsWith('.tbz') ||
        lower.endsWith('.tar.gz') ||
        lower.endsWith('.tgz') ||
        lower.endsWith('.tar.xz') ||
        lower.endsWith('.txz') ||
        lower.endsWith('.tar');
  }

  /// 解开模型压缩包。
  ///
  /// zip 走项目自己的 [Zip]（它还管加密包那套）；tar.bz2 交给 archive 的
  /// extractFileToDisk——sherpa 官方发的 TTS 模型全是 tar.bz2，而且像 kokoro 那样
  /// 带 espeak-ng-data 的有 400 多个文件，逐个列进清单不现实。
  ///
  /// **必须扔进 isolate**：bz2 解压是纯 Dart 的重 CPU 活，一百多 MB 在主线程上解
  /// 会把界面卡到 ANR。
  static Future<void> _extract(String archivePath, String dir) async {
    if (archivePath.toLowerCase().endsWith('.zip')) {
      await Zip.uncompressStream(File(archivePath), dir);
      return;
    }
    await Isolate.run(() => extractFileToDisk(archivePath, dir));
  }

  static Future<void> remove(String modelId) async {
    await Folder.delete(await dirOf(modelId));
    // 指着已删模型的选中记录要一起清掉，否则 selectedFor 每次都要多绕一圈回退逻辑。
    for (final role in AiRole.values) {
      if ((await Db().db.kvDao.getStr(_kOf(role))) == modelId) {
        await Db().db.kvDao.delete([_kOf(role)]);
      }
    }
  }

  /// 装失败就把整个目录删掉。留着半成品最危险的地方在于它看起来像装好了。
  static Future<void> _cleanFailed(String modelId) async {
    await Folder.delete(await dirOf(modelId));
  }

  /// 校验一个已落盘的文件是否就是清单里那一个。
  ///
  /// 有 sha1 就比 sha1。没有 sha1（清单里 h 为空）就退回比体积——上游 HuggingFace
  /// 给的是 git blob oid 而不是内容 sha1，拿不到真 sha1 就只能这样。体积校验挡不住
  /// 内容被篡改，但挡得住最现实的两种失败：下载被截断，和 404 的 HTML 页面被当成
  /// 模型存下来（那种"模型"几十 KB，一比体积就露馅）。
  static Future<bool> _verify(String path, AiModelFile unit) async {
    final f = File(path);
    if (!await f.exists()) {
      return false;
    }
    if (unit.hash.isNotEmpty) {
      return await Hash.toSha1(path) == unit.hash;
    }
    if (unit.size > 0) {
      return await f.length() == unit.size;
    }
    // 既没 hash 也没 size 的条目只能认它存在。清单写成这样是清单的问题。
    return true;
  }

  static Future<void> _deleteQuietly(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (e) {
      debugPrint('AiModelHelp._deleteQuietly($path) failed: $e');
    }
  }

  /// 目录里只有一个子目录、没有任何文件时，把子目录的内容提上来一层。
  static Future<void> _flattenSingleRoot(String dir) async {
    try {
      final d = Directory(dir);
      final entries = await d.list(followLinks: false).toList();
      final dirs = entries.whereType<Directory>().toList();
      final files = entries.whereType<File>().where((f) => !f.path.endsWith(okMarker)).toList();
      if (dirs.length != 1 || files.isNotEmpty) {
        return;
      }
      final inner = dirs.first;
      for (final e in await inner.list(followLinks: false).toList()) {
        final name = e.path.split(Platform.pathSeparator).last;
        await e.rename(dir.joinPath(name));
      }
      await inner.delete(recursive: true);
    } catch (e) {
      debugPrint('AiModelHelp._flattenSingleRoot failed: $e');
    }
  }
}
