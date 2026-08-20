import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/zip.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
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

        var result = await DownloadDoc.start(
          unit.url,
          relTmp,
          progressCallback: (_, count, total, _) => onProgress?.call(i + 1, units.length, count, total),
        );
        if (result == DownloadDocResult.needSkipSsl) {
          result = await DownloadDoc.start(
            unit.url,
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
        await Zip.uncompressStream(File(zipPath), dir);
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
