import 'dart:convert';
import 'dart:io';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/book_cache_version.dart';
import 'package:repeat_flutter/logic/classroom_doc_help.dart';
import 'package:repeat_flutter/logic/model/classroom_content.dart';

import 'util.dart';

/// 结构和 /classroomDoc 保持一致：课堂内容拉平在顶层，书本内容放进 'b' 数组，
/// 只是这里数组永远只有一本书。这样两个入口拿到的文档长相一致，编辑器/前端不用分两套解析。
/// 提交时 handleCommit 会把 'b' 摘出来，剩下的顶层字段写回课堂，不会进 Book.content。
Future<void> handleBook(HttpRequest request, int bookId) async {
  bookId = await Util.getBookId(request, bookId);
  final response = request.response;

  try {
    Map<String, dynamic> docMap = {};
    final book = await Db().db.bookDao.getById(bookId);
    if (book == null) {
      response.statusCode = HttpStatus.internalServerError;
      response.write('Failed to get book.');
      await response.close();
      return;
    }
    final classroom = await Db().db.classroomDao.getById(book.classroomId);
    if (classroom != null) {
      Map<String, dynamic> classroomContent;
      try {
        classroomContent = jsonDecode(classroom.content) as Map<String, dynamic>;
      } catch (e) {
        classroomContent = {};
      }
      // 'b' 是课堂文档里书本数组的保留 key，本来就不该在 Classroom.content 里
      classroomContent.remove(ClassroomDocField.books);
      // 游戏数据在 Game 表里，不在 content 里，取出来挂到 'g[].d' 上让它可编辑
      await ClassroomDocHelp.fillGameData(classroomContent, databaseData: true);
      docMap.addAll(classroomContent);
      response.headers.add(Header.classroomContentVersion, '${classroom.contentVersion}');
    }

    final bookDoc = await ClassroomDocHelp.toBookDoc(
      book: book,
      rootUrl: null,
      note: true,
      databaseData: true,
    );
    if (bookDoc == null) {
      response.statusCode = HttpStatus.internalServerError;
      response.write('Failed to get book.');
      await response.close();
      return;
    }
    docMap[ClassroomDocField.books] = [bookDoc];

    response.headers.add(Header.bookCacheVersion, BookCacheVersion.get(bookId));
    String json = jsonEncode(docMap);
    response.headers.contentType = ContentType.json;
    response.write(json);
  } catch (e) {
    response.statusCode = HttpStatus.internalServerError;
  }
  await response.close();
}
