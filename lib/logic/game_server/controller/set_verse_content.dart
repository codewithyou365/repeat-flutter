import 'package:get/get.dart';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/message.dart';
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/gs_cr_repeat_logic.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class SetVerseContentReq {
  int gameId;
  String content;

  SetVerseContentReq(this.gameId, this.content);

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'content': content,
    };
  }

  factory SetVerseContentReq.fromJson(Map<String, dynamic> json) {
    return SetVerseContentReq(
      json['gameId'] as int,
      json['content'] as String,
    );
  }
}

Future<message.Response?> setVerseContent(message.Request req, GameUser? user, Server<GameUser> server) async {
  if (user == null) {
    return message.Response(error: GameServerError.serviceStopped.name);
  }
  final reqBody = SetVerseContentReq.fromJson(req.data);
  final game = await Db().db.gameDao.one(reqBody.gameId);
  if (game == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  var ok = await Db().db.scheduleDao.tUpdateVerseContent(game.verseKeyId, reqBody.content);
  if (!ok) {
    String content = Snackbar.popContent();
    if (content.isNotEmpty) {
      return message.Response(error: content);
    } else {
      return message.Response(error: GameServerError.contentCantBeSave.name);
    }
  }
  Get.find<GsCrRepeatLogic>().update([GsCrRepeatLogic.id]);
  await Db().db.gameDao.clearGame(reqBody.gameId, user.id!, reqBody.content);
  server.broadcast(Request(path: Path.refreshGame, data: {"id": game.id, "time": game.time}));
  return message.Response();
}
