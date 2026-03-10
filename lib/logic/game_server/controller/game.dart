import 'dart:async';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';



import 'js/js_runtime.dart';


Future<message.Response?> game(
  message.Request req,
  GameUser user,
  Server<GameUser> server,
  JsRuntime jsRuntime,
) async {
  String? jsMethod = req.headers["jsMethod"];
  if (jsMethod == null) {
    return message.Response(
      status: 500,
      error: "Missing jsMethod header",
    );
  }
  req.data;
  final payload = {
    "data": req.data,
    "userId": user.id,
  };
  final jsResult = await jsRuntime.invoke(jsMethod, payload);
  if (jsResult != null) {
    return message.Response(
      headers: jsResult["headers"] ?? {},
      data: jsResult["data"],
      error: jsResult["error"] ?? '',
      status: jsResult["status"] ?? 200,
    );
  } else {
    return message.Response(
      status: 500,
      data: jsResult?["message"] ?? "Unknown JS Error",
    );
  }
}
