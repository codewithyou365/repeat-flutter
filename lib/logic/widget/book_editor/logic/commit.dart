import 'dart:convert';
import 'dart:io';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/edit_book_history.dart';
import 'package:repeat_flutter/logic/cache_help.dart';
import 'package:repeat_flutter/logic/reimport_help.dart';

import 'constant.dart';

Future<void> handleCommit(HttpRequest request, int bookId) async {
  final response = request.response;
  List<String> bookCacheVersionHeader = request.headers[Header.bookCacheVersion] ?? [];

  try {
    final content = await utf8.decoder.bind(request).join();
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
    if (CacheHelp.getCacheVersion(bookId) != bookCacheVersion) {
      response.statusCode = HttpStatus.ok;
      response.write("Commit failed because the version is not consistent");
      return;
    }
    final Map<String, dynamic> jsonData = jsonDecode(content);

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
