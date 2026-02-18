import 'dart:io';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';

Future<void> handleGetEditorStatus(HttpRequest request, K k) async {
  final response = request.response;

  try {
    var v = await Db().db.kvDao.one(k);
    response.statusCode = HttpStatus.ok;
    response.write(v?.value ?? "0");
  } catch (e) {
    response.statusCode = HttpStatus.internalServerError;
  }
  await response.close();
}

Future<void> handleSetEditorStatus(HttpRequest request, K k) async {
  final response = request.response;

  try {
    String req = await request.bytesToString();
    await Db().db.kvDao.insertOrReplace(Kv(k, "${int.parse(req)}"));
    response.statusCode = HttpStatus.ok;
  } catch (e) {
    response.statusCode = HttpStatus.internalServerError;
  }
  await response.close();
}
