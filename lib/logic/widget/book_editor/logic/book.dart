import 'dart:convert';
import 'dart:io';
import 'package:repeat_flutter/logic/cache_help.dart';
import 'package:repeat_flutter/logic/doc_help.dart';

import 'constant.dart';

Future<void> handleBook(HttpRequest request, int bookId) async {
  final response = request.response;

  try {
    Map<String, dynamic> docMap = {};
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
    response.headers.add(Header.bookCacheVersion, CacheHelp.getCacheVersion(bookId));
    String json = jsonEncode(docMap);
    response.headers.contentType = ContentType.json;
    response.write(json);
  } catch (e) {
    response.statusCode = HttpStatus.internalServerError;
  }
  await response.close();
}
