import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class DocPath {
  static const String content = "c";
  static const String zipRootFile = "__root.json";

  static String getRelativeIndexPath(int contentSerial) {
    return getRelativePath(contentSerial).joinPath(getIndexFileName());
  }

  static String getIndexFileName() {
    return "index.json";
  }

  static String getRelativePath(int contentSerial) {
    return '${Classroom.curr}'.joinPath('$contentSerial');
  }

  static Future<String> getContentPath() async {
    return await _getPath(content);
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
}

enum ProgressState {
  unfinished,
  familiar,
  unfamiliar;
}

enum Repeat {
  normal,
  justView;
}

enum MatchType {
  word,
  single,
  all;
}

enum ImportResult {
  success,
  error,
  successButSomeSegmentsAreSurplus,
}

class DownloadConstant {
  static const String userAgent = "B20240321";
  static const String defaultUrl = 'http://127.0.0.1:40321/';
}
