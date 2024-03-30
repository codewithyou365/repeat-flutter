import 'package:dio/dio.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/cache_file.dart';

typedef DownloadProgressCallback = void Function(int startTime, int count, int total, bool finish);

Future<void> downloadFile(String urlPath, String localPath, {DownloadProgressCallback? progressCallback}) async {
  var cacheFile = CacheFile(urlPath);
  await Db().db.cacheFileDao.insertCacheFile(cacheFile);
  int startTime = DateTime.now().millisecondsSinceEpoch;
  int lastUpdateTime = 0;
  int fileCount = 1;
  int fileTotal = -1;
  var dio = Dio();
  try {
    await dio.download(urlPath, localPath, onReceiveProgress: (int count, int total) {
      fileCount = count;
      if ((DateTime.now().millisecondsSinceEpoch - lastUpdateTime) > 100) {
        lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
        fileTotal = total;
        Db().db.cacheFileDao.updateProgressByUrl(urlPath, count, total);
        if (progressCallback != null) {
          progressCallback(startTime, count, total, false);
        }
      }
    });
    if (fileTotal == -1) {
      fileTotal = fileCount;
    }
    await Db().db.cacheFileDao.updateFinish(urlPath);
    if (progressCallback != null) {
      progressCallback(startTime, fileTotal, fileTotal, true);
    }
  } on DioException catch (e) {
    cacheFile = CacheFile(urlPath, msg: e.message.toString());
    Db().db.cacheFileDao.updateCacheFile(cacheFile);
  }
}
