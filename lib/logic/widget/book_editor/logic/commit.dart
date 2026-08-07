import 'dart:convert';
import 'dart:io';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/edit_book_history.dart';
import 'package:repeat_flutter/logic/book_cache_version.dart';
import 'package:repeat_flutter/logic/model/classroom_content.dart';
import 'package:repeat_flutter/logic/reimport_help.dart';

import 'util.dart';

Future<void> handleCommit(HttpRequest request, int bookId) async {
  bookId = await Util.getBookId(request, bookId);
  final response = request.response;
  List<String> bookCacheVersionHeader = request.headers[Header.bookCacheVersion] ?? [];

  try {
    final content = await utf8.decoder.bind(request).join();
    // 单本入口只收单本文档。课堂文档发到这里的话，'b' 里那些书会被当成书本内容整个写进这一本，
    // 所以宁可整份退回去，不做任何猜测。
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
    // 头可以不带（老页面/脚本），文档长相不会骗人：'b' 只出现在课堂文档里
    if (jsonData.containsKey(ClassroomDocField.books)) {
      response.statusCode = HttpStatus.badRequest;
      response.write('Commit failed: the document has a "${ClassroomDocField.books}" array, it looks like a classroom document.');
      return;
    }

    // 课堂内容是单独一块（见 handleBook），先摘出来写回课堂，剩下的才是书本内容
    final classroomContent = jsonData.remove(ClassroomDocField.classroom);
    if (classroomContent != null) {
      if (classroomContent is! Map<String, dynamic>) {
        response.statusCode = HttpStatus.badRequest;
        response.write('Commit failed: "${ClassroomDocField.classroom}" must be an object.');
        return;
      }
      final book = await Db().db.bookDao.getById(bookId);
      final classroom = book == null ? null : await Db().db.classroomDao.getById(book.classroomId);
      if (classroom == null) {
        response.statusCode = HttpStatus.badRequest;
        response.write('Commit failed: classroom not found.');
        return;
      }
      // 课堂内容可能在 App 里或课堂级编辑器里被改过，版本对不上就整份不提交
      final classroomVersionHeader = request.headers[Header.classroomContentVersion] ?? [];
      if (classroomVersionHeader.isEmpty || classroomVersionHeader.first != '${classroom.contentVersion}') {
        response.statusCode = HttpStatus.ok;
        response.write("Commit failed because the classroom version is not consistent");
        return;
      }
      classroomContent.remove(ClassroomDocField.books);
      await Db().db.classroomDao.updateContent(classroom.id, jsonEncode(classroomContent));
    }

    var result = await ReimportHelp.reimport(bookId, jsonData);
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
