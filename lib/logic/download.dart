import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/cache_file.dart';
import 'package:repeat_flutter/logic/constant.dart';

typedef DownloadProgressCallback = void Function(int startTime, int count, int total, bool finish);
typedef Finish = Future<FileLocation> Function(FileLocation fp);

Future<CacheFile?> downloadFilePath(String url) async {
  return await Db().db.cacheFileDao.one(url);
}

Future<bool> downloadFile(String urlPath, Finish finish, {DownloadProgressCallback? progressCallback}) async {
  var id = await Db().db.cacheFileDao.insert(urlPath);
  int startTime = DateTime.now().millisecondsSinceEpoch;
  int lastUpdateTime = 0;
  int fileCount = 1;
  int fileTotal = -1;
  var dio = Dio();
  try {
    var directory = await getTemporaryDirectory();
    var rootPath = "${directory.path}/${CacheFilePrefixPath.content}";
    var fl = FileLocation(rootPath, "temp");
    await dio.download(urlPath, fl.path, onReceiveProgress: (int count, int total) {
      fileCount = count;
      if ((DateTime.now().millisecondsSinceEpoch - lastUpdateTime) > 100) {
        lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
        fileTotal = total;
        Db().db.cacheFileDao.updateProgressById(id, count, total);
        if (progressCallback != null) {
          progressCallback(startTime, count, total, false);
        }
      }
    });
    if (fileTotal == -1) {
      fileTotal = fileCount;
    }
    var newFl = await finish(fl);
    await ensureFolderExists(newFl.folderPath);
    await File(fl.path).rename(newFl.path);
    await Db().db.cacheFileDao.updateFinish(id, newFl.path);
    if (progressCallback != null) {
      progressCallback(startTime, fileTotal, fileTotal, true);
    }
    return true;
  } on Exception catch (e) {
    Db().db.cacheFileDao.updateCacheFile(id, e.toString());
  }
  return false;
}
