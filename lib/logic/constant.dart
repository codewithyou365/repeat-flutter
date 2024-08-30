import 'package:repeat_flutter/common/folder.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class DocPath {
  static const String content = "c";
  static const String zipSave = "zs";
  static const String zipTarget = "zt";
  static const String zipIndexFile = "__index.json";

  static Future<String> getContentPath() async {
    return await _getPath(content);
  }

  static Future<String> getZipSavePath({clearFirst = false}) async {
    return await _getPath(zipSave, clearFirst: clearFirst);
  }

  static Future<String> getZipTargetPath({clearFirst = false}) async {
    return await _getPath(zipTarget, clearFirst: clearFirst);
  }

  static Future<String> _getPath(String dir, {clearFirst = false}) async {
    var directory = await sqflite.getDatabasesPath();
    var path = "$directory/$dir";
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
