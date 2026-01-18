import 'dart:io';

import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/base/constant.dart';

class Header {
  static const String bookCacheVersion = "book-cache-version";
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
