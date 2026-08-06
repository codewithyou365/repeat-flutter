import 'dart:io';

import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/base/constant.dart';

class Header {
  static const String bookCacheVersion = "book-cache-version";
  static const String classroomCacheVersion = "classroom-cache-version";

  /// 单本编辑时课堂内容自己的乐观锁（[Classroom.contentVersion]）。
  /// 单本文档里带了课堂内容（见 [ClassroomDocField.classroom]），
  /// 所以除了书本版本还要再对一次课堂版本，免得覆盖掉别处刚改的课堂内容。
  static const String classroomContentVersion = "classroom-content-version";
}

class Util {
  static Future<int> getBookId(HttpRequest request, int defaultBookId) async {
    final requestBookId = request.uri.queryParameters['b'];
    if (requestBookId == null || requestBookId.isEmpty) {
      return defaultBookId;
    }
    try {
      return int.parse(requestBookId);
    } catch (e) {
      return defaultBookId;
    }
  }

  /// 编辑器可以跨课堂切书，所以课堂取的是"当前这本书所在的课堂"，不是 Classroom.curr。
  /// 也支持直接用 ?c= 指定课堂（课堂里一本书都没有时只能靠它）。
  static Future<int?> getClassroomId(HttpRequest request, int defaultBookId) async {
    final requestClassroomId = request.uri.queryParameters['c'];
    if (requestClassroomId != null && requestClassroomId.isNotEmpty) {
      final id = int.tryParse(requestClassroomId);
      if (id != null) {
        return id;
      }
    }
    final bookId = await getBookId(request, defaultBookId);
    final book = await Db().db.bookDao.getById(bookId);
    return book?.classroomId;
  }

  /// 上传落在哪：显式给了 ?c= 就是课堂级资源目录（游戏 zip 放这里，见 Classroom.content 的 'g'），
  /// 否则还是书本目录。课堂级编辑（All books）传的就是 ?c=。
  static Future<Directory?> getUploadDir(HttpRequest request, Directory? defaultDir) async {
    final requestClassroomId = request.uri.queryParameters['c'];
    final classroomId = requestClassroomId == null ? null : int.tryParse(requestClassroomId);
    if (classroomId == null) {
      return getDir(request, defaultDir);
    }
    final rootDir = await DocPath.getContentPath();
    final dir = Directory(rootDir.joinPath(DocPath.getClassroomResRelativePath(classroomId)));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<Directory?> getDir(HttpRequest request, Directory? defaultDir) async {
    final int bookId = await getBookId(request, -1);
    if (bookId == -1) {
      return defaultDir;
    }
    var book = await Db().db.bookDao.getById(bookId);

    if (book == null) {
      return null;
    }
    final rootDir = await DocPath.getContentPath();
    final appDir = rootDir.joinPath('${book.classroomId}').joinPath('$bookId');
    final dir = Directory(appDir);
    if (!await dir.exists()) {
      return null;
    }
    return dir;
  }
}
