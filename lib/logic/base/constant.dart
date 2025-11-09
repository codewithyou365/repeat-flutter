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
    return '${Classroom.curr}'.joinPath('$bookId');
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
  normal,
  justView,
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

enum CloseEyesEnum {
  transparent(null, Color.fromRGBO(0, 0, 0, 0)),
  translucence(null, Color.fromRGBO(0, 0, 255, 0.1)),
  opacity(Color.fromRGBO(255, 255, 255, 0.3), Colors.black),
  none(null, null);

  final Color? foregroundColor;
  final Color? backgroundColor;

  const CloseEyesEnum(this.foregroundColor, this.backgroundColor);
}

class DownloadConstant {
  static const String userAgent = "B20240321";
  static const String defaultUrl = 'http://127.0.0.1:40321/';
}
