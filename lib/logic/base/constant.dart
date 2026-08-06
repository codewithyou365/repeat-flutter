import 'package:flutter/material.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class DocPath {
  static const String content = "c";
  static const String ssl = "s";
  static const String zipRootFile = "__root.json";

  static String getRelativeIndexPath(int bookId) {
    return getRelativePath(bookId).joinPath(getIndexFileName());
  }

  static String getIndexFileName() {
    return "index.json";
  }

  static String getRelativePath(int bookId) {
    return getRelativePathOf(Classroom.curr, bookId);
  }

  /// 课堂显式给出的版本。课堂导入/课堂级编辑动的不是"当前课堂"，
  /// 这些地方必须用它，不能走 [Classroom.curr]。
  static String getRelativePathOf(int classroomId, int bookId) {
    return '$classroomId'.joinPath('$bookId');
  }

  static String getRelativeIndexPathOf(int classroomId, int bookId) {
    return getRelativePathOf(classroomId, bookId).joinPath(getIndexFileName());
  }

  /// 课堂自己的目录（课堂级 index.json、导入暂存都放这里）
  static String getClassroomRelativePath(int classroomId) {
    return '$classroomId';
  }

  static Future<String> getContentPath() async {
    return await _getPath(content);
  }

  static Future<String> getSslPath() async {
    return await _getPath(ssl);
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
  unfamiliar,
}

enum RepeatType {
  browse,
  examine,
}

enum MatchType {
  word,
  single,
  all,
}

enum ContentTypeEnum {
  book,
  chapter,
  verse,
}

enum RepeatViewEnum {
  text,
  audio,
  video,
}

enum CloseEyesModeEnum {
  transparent(null, Color.fromRGBO(0, 0, 0, 0)),
  translucence(null, Color.fromRGBO(0, 0, 255, 0.1)),
  opacity(Color.fromRGBO(255, 255, 255, 0.3), Colors.black);

  final Color? foregroundColor;
  final Color? backgroundColor;

  const CloseEyesModeEnum(
    this.foregroundColor,
    this.backgroundColor,
  );
}

enum RepeatFullScreenMode {
  gameWebView,
  closeEyes,
  none,
}

class DownloadConstant {
  static const String userAgent = "B20240321";
  static const String defaultUrl = 'http://127.0.0.1:40321/';
}
