import 'package:flutter/material.dart';
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class DocPath {
  static const String content = "c";
  static const String ssl = "s";
  static const String zipRootFile = "__root.json";

  /// 课堂文件目录名（files 的缩写），同时也是分享 zip 里存文件的目录名。
  ///
  /// 全课堂所有 json 引用的文件都在这一个目录下：文件名本来就是 sha1 分桶的
  /// （`<hash 前两位>/<hash 剩余>.<扩展名>`，见 [DownloadContent.path]），天生全局唯一，
  /// 再按书本切一层目录没有任何意义——同一个媒体被两本书引用还得存两份。
  /// 课堂级资源（游戏 zip、提示的字体和提示服务 zip）也放这里，不再单开目录。
  static const String classroomFiles = "f";

  /// AI 模型目录名，是 content("c") 的兄弟目录而不是它的子目录。
  ///
  /// 为什么不能放 c/ 下面：模型动辄几百 MB，而 c/ 有三重暴露——
  /// 1. 课堂分享的局域网 HTTP 服务把 content 根下的任意路径当文件下发（见 ScShareLogic），
  ///    模型会在开分享时全网可下；
  /// 2. f/ 是课堂分享 zip 的载荷，会被打包发出去；
  /// 3. f/ 是"没被任何 'd' 引用就可回收"的媒体池，模型会被当垃圾清掉。
  /// 放 `<databasesPath>/m` 三条都不沾。
  static const String model = "m";

  static String getIndexFileName() {
    return "index.json";
  }

  /// 课堂自己的目录（课堂级 index.json、导入暂存都放这里）
  static String getClassroomRelativePath(int classroomId) {
    return '$classroomId';
  }

  /// 课堂显式给出的版本。课堂导入/课堂级编辑动的不是"当前课堂"，
  /// 这些地方必须用它，不能走 [Classroom.curr]。
  static String getFilesRelativePathOf(int classroomId) {
    return getClassroomRelativePath(classroomId).joinPath(classroomFiles);
  }

  static String getFilesRelativePath() {
    return getFilesRelativePathOf(Classroom.curr);
  }

  static Future<String> getContentPath() async {
    return await _getPath(content);
  }

  static Future<String> getSslPath() async {
    return await _getPath(ssl);
  }

  static Future<String> getModelPath() async {
    return await _getPath(model);
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
