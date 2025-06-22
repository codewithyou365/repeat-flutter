import 'dart:io';

import 'package:dio/dio.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

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

  int startTime = DateTime.now().millisecondsSinceEpoch;
  int lastUpdateTime = 0;
  int fileCount = 1;
  int fileTotal = -1;
  var dio = Dio();

  try {
    var rootPath = await DocPath.getContentPath();
    var targetFilePath = ap ?? rootPath.joinPath(rp!);
    var exist = false;
    if (hash != "") {
      String fileHash = await Hash.toSha1(targetFilePath);
      if (fileHash == hash) {
        exist = true;
      }
    }
    if (exist == true) {
      if (progressCallback != null) {
        progressCallback(startTime, 100, 100, true);
      }
      return true;
    }
    var fl = DocLocation(rootPath, "temp");
    await dio.download(url, fl.path, onReceiveProgress: (int count, int total) {
      fileCount = count;
      if ((DateTime.now().millisecondsSinceEpoch - lastUpdateTime) > 100) {
        lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
        fileTotal = total;
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
    await File(fl.path).rename(targetFilePath);
    if (progressCallback != null) {
      progressCallback(startTime, fileTotal, fileTotal, true);
    }
    return true;
  } on Exception catch (e) {
    Snackbar.show(I18nKey.labelDataAnomaly.trArgs([e.toString()]));
  }
  return false;
}
