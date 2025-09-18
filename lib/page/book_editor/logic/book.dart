import 'dart:convert';
import 'dart:io';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/logic/doc_help.dart';

Future<void> handleBook(HttpRequest request, int bookId) async {
  final response = request.response;

  try {
    var rootIndex = request.requestedUri.toString().lastIndexOf('/');
    var url = request.requestedUri.toString().substring(0, rootIndex);
    url = url.joinPath(Classroom.curr.toString());
    url = url.joinPath(bookId.toString());
    Map<String, dynamic> docMap = {};
    bool success = await DocHelp.getDocMapFromDb(
      bookId: bookId,
      ret: docMap,
      note: true,
      databaseData: true,
      rootUrl: url,
    );

    if (!success) {
      response.statusCode = HttpStatus.internalServerError;
      response.write('Failed to get book.');
      await response.close();
      return;
    }
    String json = jsonEncode(docMap);
    response.headers.contentType = ContentType.json;
    response.write(json);
  } catch (e) {
    response.statusCode = HttpStatus.internalServerError;
  }
  await response.close();
}
