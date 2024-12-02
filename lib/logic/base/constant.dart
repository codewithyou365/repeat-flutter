import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class DocPath {
  static const String content = "c";
  static const String zipSave = "zs";
  static const String zipTarget = "zt";
  static const String zipIndexFile = "__index.json";

  static String getRelativeMediaPath(int materialSerial, int lessonIndex, String mediaExtension) {
    return getRelativePath(materialSerial).joinPath(getMediaFileName(lessonIndex, mediaExtension));
  }

  static String getRelativeIndexPath(int materialSerial) {
    return getRelativePath(materialSerial).joinPath(getIndexFileName());
  }

  static String getMediaFileName(int lessonIndex, String mediaExtension) {
    return "$lessonIndex.$mediaExtension";
  }

  static String getIndexFileName() {
    return "index.json";
  }

  static String getRelativePath(int materialSerial) {
    return '${Classroom.curr}'.joinPath('$materialSerial');
  }

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

class Download {
  static const String userAgent = "B20240321";
}
