import 'dart:convert';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

class LatestGameRes {
  int gameId;
  String w;

  LatestGameRes(this.gameId, this.w);

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'w': w,
    };
  }

  factory LatestGameRes.fromJson(Map<String, dynamic> json) {
    return LatestGameRes(
      json['gameId'] as int,
      json['w'] as String,
    );
  }
}

Future<message.Response?> latestGame(message.Request req) async {
  final user = await Db().db.gameUserDao.loginByToken(req.headers['token'] ?? '');
  if (user.isEmpty()) {
    return message.Response(error: GameServerError.tokenExpired.name);
  }
  final game = await Db().db.gameDao.getLatestOne();
  if (game == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  LatestGameRes res = LatestGameRes(game.id, game.w);
  return message.Response(data: jsonEncode(res.toJson()));
}
