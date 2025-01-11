import 'dart:convert';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

Future<message.Response?> loginByToken(message.Request req) async {
  final user = await Db().db.gameUserDao.loginByToken(req.headers['token'] ?? '');
  if (user.isEmpty()) {
    return message.Response(error: GameServerError.serviceStopped.name);
  }
  return message.Response(data: "");
}
