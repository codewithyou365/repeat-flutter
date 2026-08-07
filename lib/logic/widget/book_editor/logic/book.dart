import 'dart:convert';
import 'dart:io';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/book_cache_version.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/model/classroom_content.dart';

import 'util.dart';

Future<void> handleBook(HttpRequest request, int bookId) async {
  bookId = await Util.getBookId(request, bookId);
  final response = request.response;

  try {
    // 课堂内容放在书本内容前面，单本编辑也能看到并改到游戏这些课堂级的东西。
    // 提交时 handleCommit 会把它摘出来写回课堂，不会进 Book.content。
    Map<String, dynamic> docMap = {};
    final book = await Db().db.bookDao.getById(bookId);
    final classroom = book == null ? null : await Db().db.classroomDao.getById(book.classroomId);
    if (classroom != null) {
      Map<String, dynamic> classroomContent;
      try {
        classroomContent = jsonDecode(classroom.content) as Map<String, dynamic>;
      } catch (e) {
        classroomContent = {};
      }
      // 'b' 是课堂文档里书本数组的保留 key，本来就不该在 Classroom.content 里
      classroomContent.remove(ClassroomDocField.books);
      docMap[ClassroomDocField.classroom] = classroomContent;
      response.headers.add(Header.classroomContentVersion, '${classroom.contentVersion}');
    }

    bool success = await DocHelp.getDocMapFromDb(
      bookId: bookId,
      ret: docMap,
      rootUrl: null,
      note: true,
      databaseData: true,
    );

    if (!success) {
      response.statusCode = HttpStatus.internalServerError;
      response.write('Failed to get book.');
      await response.close();
      return;
    }
    response.headers.add(Header.bookCacheVersion, BookCacheVersion.get(bookId));
    String json = jsonEncode(docMap);
    response.headers.contentType = ContentType.json;
    response.write(json);
  } catch (e) {
    response.statusCode = HttpStatus.internalServerError;
  }
  await response.close();
}
