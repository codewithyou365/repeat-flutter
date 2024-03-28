import 'package:dio/dio.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/cache_file.dart';

Future<void> downloadFile(String urlPath, String localPath, {ProgressCallback? progressCallback}) async {
  var cacheFile = CacheFile(urlPath, false);
  Db().db.cacheFileDao.insertCacheFile(cacheFile);

  var dio = Dio();
  try {
    await dio.download(urlPath, localPath, onReceiveProgress: progressCallback);
    print("download path: $localPath");
    cacheFile = CacheFile(urlPath, true);
    Db().db.cacheFileDao.updateCacheFile(cacheFile);
  } on DioException catch (e) {
    cacheFile = CacheFile(urlPath, false, msg: e.message.toString());
    Db().db.cacheFileDao.updateCacheFile(cacheFile);
  }
}
