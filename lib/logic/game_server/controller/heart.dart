import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/message.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
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

Future<message.Response?> heart(message.Request req, GameUser? user) async {
  if (req.headers[Header.age.name] == null) {
    return message.Response(error: GameServerError.serviceStopped.name);
  }

  if (user == null) {
    return message.Response(error: GameServerError.serviceStopped.name);
  }
  int age = int.parse(req.headers[Header.age.name]!);
  return message.Response(data: age);
}
