import 'dart:convert';
import 'dart:io';
import 'package:repeat_flutter/logic/reimport_help.dart';

Future<void> handleCommit(HttpRequest request, int bookId) async {
  final response = request.response;

  try {
    final content = await utf8.decoder.bind(request).join();
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
    response.write("Error : $e");
    print("Commit error: $e\n$st");
  }
  await response.close();
}
