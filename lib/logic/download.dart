import 'dart:io';

import 'package:dio/dio.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/doc.dart';
import 'package:repeat_flutter/logic/base/constant.dart';

typedef DownloadProgressCallback = void Function(int startTime, int count, int total, bool finish);
typedef Finish = Future<void> Function(DocLocation fp, bool tempFile);

Future<bool> downloadDoc(
  String url,
  String path, {
  String hash = "",
  DownloadProgressCallback? progressCallback,
}) async {
  String? rp;
  String? ap;
  if (path.startsWith("/")) {
    ap = path;
  } else {
    rp = path;
  }

  var id = 0;
  Doc? doc;
  if (rp != null) {
    doc = await Db().db.docDao.insertByPath(rp);
    id = doc.id!;
  }
  int startTime = DateTime.now().millisecondsSinceEpoch;
  int lastUpdateTime = 0;
  int fileCount = 1;
  int fileTotal = -1;
  var dio = Dio();
  try {
    var rootPath = await DocPath.getContentPath();
    if (doc != null) {
      var exist = false;
      if (doc.path != "" && doc.hash != "" && hash != "") {
        if (doc.hash == hash) {
          String fileHash = await Hash.toSha1(rootPath.joinPath(doc.path));
          if (fileHash == hash) {
            exist = true;
          }
        }
      }
      if (exist == true) {
        if (progressCallback != null) {
          progressCallback(startTime, doc.total, doc.total, true);
        }
        return true;
      }
    }
    var fl = DocLocation(rootPath, "temp");
    await dio.download(url, fl.path, onReceiveProgress: (int count, int total) {
      fileCount = count;
      if ((DateTime.now().millisecondsSinceEpoch - lastUpdateTime) > 100) {
        lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
        fileTotal = total;
        if (rp != null) {
          Db().db.docDao.updateProgressById(id, count, total);
        }
        if (progressCallback != null) {
          progressCallback(startTime, count, total, false);
        }
      }
    }, options: Options(headers: {HttpHeaders.userAgentHeader: DownloadConstant.userAgent}));
    if (fileTotal == -1) {
      fileTotal = fileCount;
    }
    DocLocation dl = DocLocation.create(path);
    await Folder.ensureExists(rootPath.joinPath(dl.folderPath));
    var targetFilePath = ap ?? rootPath.joinPath(rp!);
    await File(fl.path).rename(targetFilePath);
    if (rp != null) {
      String hash = await Hash.toSha1(targetFilePath);
      await Db().db.docDao.updateFinish(id, url, rp, hash);
    }
    if (progressCallback != null) {
      progressCallback(startTime, fileTotal, fileTotal, true);
    }
    return true;
  } on Exception catch (e) {
    if (rp != null) {
      Db().db.docDao.updateDoc(id, e.toString());
    }
  }
  return false;
}
