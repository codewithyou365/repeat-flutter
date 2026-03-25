import 'dart:async';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/logic/tip_server/constant.dart';
import 'package:repeat_flutter/logic/widget/tip/tip_state.dart';

Future<message.Response?> tipKey(message.Request req) async {
  if (TipState.tip == null) {
    return message.Response(error: TipServerError.tipNotFound.name);
  }
  return message.Response(data: TipState.tip!.k);
}
