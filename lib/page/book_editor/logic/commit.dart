import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:repeat_flutter/logic/import_help.dart';
import 'package:repeat_flutter/page/content/content_logic.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';

Future<void> handleCommit(HttpRequest request, int bookId) async {
  final response = request.response;

  try {
    final content = await utf8.decoder.bind(request).join();
    final Map<String, dynamic> jsonData = jsonDecode(content);

    var result = await ImportHelp.reimport(bookId, jsonData);
    if (!result) {
      response.statusCode = HttpStatus.expectationFailed;
      response.write("Commit failed.");
      return;
    }
    await Get.find<GsCrLogic>().init();
    await Get.find<ContentLogic>().change();
    response.statusCode = HttpStatus.ok;
    response.write("Commit successful. Received ${jsonData.length} keys.");
  } catch (e, st) {
    response.statusCode = HttpStatus.badRequest;
    response.write("Invalid JSON: $e");
    print("Commit error: $e\n$st");
  }
  await response.close();
}
