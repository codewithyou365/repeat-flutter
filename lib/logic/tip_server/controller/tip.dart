import 'dart:async';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/logic/tip_server/js/js_runtime.dart';

Future<message.Response?> tip(
  message.Request req,
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
