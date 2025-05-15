
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

class GetSegmentContentReq {
  int gameId;

  GetSegmentContentReq(this.gameId);

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
    };
  }

  factory GetSegmentContentReq.fromJson(Map<String, dynamic> json) {
    return GetSegmentContentReq(
      json['gameId'] as int,
    );
  }
}

class GetSegmentContentRes {
  String content;

  GetSegmentContentRes(this.content);

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }

  factory GetSegmentContentRes.fromJson(Map<String, dynamic> json) {
    return GetSegmentContentRes(
      json['content'] as String,
    );
  }
}

Future<message.Response?> getSegmentContent(message.Request req, GameUser? user) async {
  if (user == null) {
    return message.Response(error: GameServerError.serviceStopped.name);
  }
  final reqBody = GetSegmentContentReq.fromJson(req.data);
  final game = await Db().db.gameDao.one(reqBody.gameId);
  if (game == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  final res = GetSegmentContentRes(game.segmentContent);
  return message.Response(data: res);
}
