import 'dart:convert';
import 'dart:io';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/edit_book_history.dart';
import 'package:repeat_flutter/logic/book_cache_version.dart';
import 'package:repeat_flutter/logic/classroom_doc_help.dart';
import 'package:repeat_flutter/logic/model/classroom_content.dart';
import 'package:repeat_flutter/logic/reimport_help.dart';

import 'util.dart';

Future<void> handleCommit(HttpRequest request, int bookId) async {
  bookId = await Util.getBookId(request, bookId);
  final response = request.response;
  List<String> bookCacheVersionHeader = request.headers[Header.bookCacheVersion] ?? [];

  try {
    final content = await utf8.decoder.bind(request).join();
    // 单本入口只收单本文档（'b' 数组里只能有一本书，见下面的检查）。
    // 课堂文档的 'b' 可能有任意本数，靠 edit-unit 头先把这类请求挡在外面，不做猜测。
    final editUnit = Util.getEditUnit(request);
    if (editUnit != null && editUnit != EditUnit.book) {
      response.statusCode = HttpStatus.badRequest;
      response.write('Commit failed: this is the book endpoint but the document is "$editUnit".');
      return;
    }
    EditBookHistory history = EditBookHistory(
      bookId: bookId,
      commitDate: DateTime.now(),
      content: content,
    );
    Db().db.editBookHistoryDao.insertOrFail(history);
    var bookCacheVersion = -1;
    if (bookCacheVersionHeader.isNotEmpty) {
      bookCacheVersion = int.parse(bookCacheVersionHeader.first);
    }
    if (BookCacheVersion.get(bookId) != bookCacheVersion) {
      response.statusCode = HttpStatus.ok;
      response.write("Commit failed because the version is not consistent");
      return;
    }
    final Map<String, dynamic> jsonData = jsonDecode(content);

    // 结构和 handleBook 的响应对称：书本内容在 'b' 数组里，且这里永远只收一本
    final booksField = jsonData.remove(ClassroomDocField.books);
    if (booksField is! List || booksField.length != 1 || booksField.first is! Map<String, dynamic>) {
      response.statusCode = HttpStatus.badRequest;
      response.write('Commit failed: expected exactly one book in "${ClassroomDocField.books}".');
      return;
    }
    final Map<String, dynamic> bookData = booksField.first as Map<String, dynamic>;

    // 顶层剩下的字段是课堂内容（见 handleBook），先写回课堂，再落书本内容。
    // 是否带课堂内容以 classroom-content-version 头是否存在为准，和 handleBook 是否加了这个头对应。
    final classroomVersionHeader = request.headers[Header.classroomContentVersion] ?? [];
    if (classroomVersionHeader.isNotEmpty) {
      final book = await Db().db.bookDao.getById(bookId);
      final classroom = book == null ? null : await Db().db.classroomDao.getById(book.classroomId);
      if (classroom == null) {
        response.statusCode = HttpStatus.badRequest;
        response.write('Commit failed: classroom not found.');
        return;
      }
      // 课堂内容可能在 App 里或课堂级编辑器里被改过，版本对不上就整份不提交
      if (classroomVersionHeader.first != '${classroom.contentVersion}') {
        response.statusCode = HttpStatus.ok;
        response.write("Commit failed because the classroom version is not consistent");
        return;
      }
      // 'g[].d' 是游戏数据，写回 Game 表而不是 content（见 ClassroomDocHelp.takeGameData）
      await ClassroomDocHelp.takeGameData(classroom.id, jsonData);
      await Db().db.classroomDao.updateContent(classroom.id, jsonEncode(jsonData));
    }

    var result = await ReimportHelp.reimport(bookId, bookData);
    if (result == null) {
      response.statusCode = HttpStatus.expectationFailed;
      response.write("Commit failed.");
      return;
    }
    response.statusCode = HttpStatus.ok;
    response.write("Commit successful.\n${JsonEncoder.withIndent(' ').convert(result.toJson())}");
  } catch (e, st) {
    response.statusCode = HttpStatus.badRequest;
    response.write("Error : $e\n$st");
  } finally {
    await response.close();
  }
}
