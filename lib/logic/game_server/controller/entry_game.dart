import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

class LatestGameRes {
  int id;
  int time;

  LatestGameRes(this.id, this.time);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
    };
  }

  factory LatestGameRes.fromJson(Map<String, dynamic> json) {
    return LatestGameRes(
      json['id'] as int,
      json['time'] as int,
    );
  }
}

Future<message.Response?> entryGame(message.Request req, GameUser? user) async {
  if (user == null) {
    return message.Response(error: GameServerError.serviceStopped.name);
  }
  final game = await Db().db.gameDao.getOne();
  if (game == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  LatestGameRes res = LatestGameRes(game.id, game.time);
  return message.Response(data: res);
}
