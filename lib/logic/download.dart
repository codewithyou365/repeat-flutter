import 'dart:io';

import 'package:dio/dio.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/doc.dart';
import 'package:repeat_flutter/logic/constant.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

typedef DownloadProgressCallback = void Function(int startTime, int count, int total, bool finish);
typedef Finish = Future<DocLocation?> Function(DocLocation fp, bool tempFile);

Future<Doc?> downloadDocPath(String url) async {
  return await Db().db.docDao.one(url);
}

Future<bool> downloadDoc(String urlPath, Finish finish, {String hash = "", DownloadProgressCallback? progressCallback, withoutDb = false}) async {
  var id = 0;
  Doc? doc;
  if (!withoutDb) {
    doc = await Db().db.docDao.insert(urlPath);
    id = doc.id!;
  }
  int startTime = DateTime.now().millisecondsSinceEpoch;
  int lastUpdateTime = 0;
  int fileCount = 1;
  int fileTotal = -1;
  var dio = Dio();
  try {
    if (doc != null) {
      var exist = false;
      if (doc.path != "" && doc.hash != "" && hash != "") {
        if (doc.hash == hash) {
          String fileHash = await Hash.toSha1(doc.path);
          if (fileHash == hash) {
            exist = true;
          }
        }
      }
      if (exist == true) {
        await finish(DocLocation.create(doc.path), false);
        if (progressCallback != null) {
          progressCallback(startTime, doc.total, doc.total, true);
        }
        return true;
      }
    }
    var directory = await sqflite.getDatabasesPath();
    var rootPath = "$directory/${DocPrefixPath.content}";
    var fl = DocLocation(rootPath, "temp");
    await dio.download(urlPath, fl.path, onReceiveProgress: (int count, int total) {
      fileCount = count;
      if ((DateTime.now().millisecondsSinceEpoch - lastUpdateTime) > 100) {
        lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
        fileTotal = total;
        if (!withoutDb) {
          Db().db.docDao.updateProgressById(id, count, total);
        }
        if (progressCallback != null) {
          progressCallback(startTime, count, total, false);
        }
      }
    });
    if (fileTotal == -1) {
      fileTotal = fileCount;
    }
    var newFl = await finish(fl, true);
    if (newFl == null) {
      return false;
    }
    await ensureFolderExists(newFl.folderPath);
    await File(fl.path).rename(newFl.path);
    if (!withoutDb) {
      String hash = await Hash.toSha1(newFl.path);
      await Db().db.docDao.updateFinish(id, newFl.path, hash);
    }
    if (progressCallback != null) {
      progressCallback(startTime, fileTotal, fileTotal, true);
    }
    return true;
  } on Exception catch (e) {
    if (!withoutDb) {
      Db().db.docDao.updateDoc(id, e.toString());
    }
  }
  return false;
}
