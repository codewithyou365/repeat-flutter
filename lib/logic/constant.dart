import 'package:repeat_flutter/common/folder.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class DocPath {
  static const String content = "c";

  static Future<String> getRootPath() async {
    var directory = await sqflite.getDatabasesPath();
    var rootPath = "$directory/$content";
    Folder.ensureExists(rootPath);
    return rootPath;
  }
}

enum Repeat {
  normal,
  justView;
}
