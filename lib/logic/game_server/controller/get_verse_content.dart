
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

class GetVerseContentReq {
  int gameId;

  GetVerseContentReq(this.gameId);

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
    };
  }

  factory GetVerseContentReq.fromJson(Map<String, dynamic> json) {
    return GetVerseContentReq(
      json['gameId'] as int,
    );
  }
}

class GetVerseContentRes {
  String content;

  GetVerseContentRes(this.content);

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }

  factory GetVerseContentRes.fromJson(Map<String, dynamic> json) {
    return GetVerseContentRes(
      json['content'] as String,
    );
  }
}

Future<message.Response?> getVerseContent(message.Request req, GameUser? user) async {
  if (user == null) {
    return message.Response(error: GameServerError.serviceStopped.name);
  }
  final reqBody = GetVerseContentReq.fromJson(req.data);
  final game = await Db().db.gameDao.one(reqBody.gameId);
  if (game == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  final res = GetVerseContentRes(game.verseContent);
  return message.Response(data: res);
}
