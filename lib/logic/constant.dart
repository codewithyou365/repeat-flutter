import 'package:repeat_flutter/common/folder.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class DocPath {
  static const String content = "c";
  static const String zipDownload = "zd";
  static const String zipTarget = "zt";
  static const String zipIndexFile = "__index.json";

  static Future<String> getContentPath() async {
    var directory = await sqflite.getDatabasesPath();
    var path = "$directory/$content";
    await Folder.ensureExists(path);
    return path;
  }

  static Future<String> getZipTargetPath({clearFirst = false}) async {
    var directory = await sqflite.getDatabasesPath();
    var path = "$directory/$zipTarget";
    if (clearFirst) {
      await Folder.delete(path);
    }
    await Folder.ensureExists(path);
    return path;
  }

  static Future<String> getZipIndexFilePath() async {
    var directory = await sqflite.getDatabasesPath();
    var path = "$directory/$zipTarget/$zipIndexFile";
    return path;
  }
}

enum Repeat {
  normal,
  justView;
}
