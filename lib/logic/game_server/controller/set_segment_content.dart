import 'dart:convert';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/message.dart';
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/logic/repeat_doc_help.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/gs_cr_repeat_logic.dart';

class SetSegmentContentReq {
  int gameId;
  String content;

  SetSegmentContentReq(this.gameId, this.content);

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'content': content,
    };
  }

  factory SetSegmentContentReq.fromJson(Map<String, dynamic> json) {
    return SetSegmentContentReq(
      json['gameId'] as int,
      json['content'] as String,
    );
  }
}

Future<message.Response?> setSegmentContent(message.Request req, GameUser? user, Server<GameUser> server) async {
  if (user == null) {
    return message.Response(error: GameServerError.serviceStopped.name);
  }
  if (!Get.find<GsCrRepeatLogic>().state.editInGame.value) {
    return message.Response(error: GameServerError.editModeDisabled.name);
  }
  final reqBody = SetSegmentContentReq.fromJson(req.data);
  final game = await Db().db.gameDao.one(reqBody.gameId);
  if (game == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  var map = await RepeatDocHelp.getAndCacheJsonQa(game.contentSerial);
  if (map == null) {
    return message.Response(error: GameServerError.contentNotFound.name);
  }
  List<dynamic> lessons = List<dynamic>.from(map['lesson']);
  if (game.lessonIndex >= lessons.length) {
    return message.Response(error: GameServerError.contentNotFound.name);
  }
  map['lesson'] = lessons;
  List<dynamic> segments = List<dynamic>.from(lessons[game.lessonIndex]['segment']);
  if (game.segmentIndex >= segments.length) {
    return message.Response(error: GameServerError.contentNotFound.name);
  }
  lessons[game.lessonIndex]['segment'] = segments;
  segments[game.segmentIndex] = jsonDecode(reqBody.content);
  var indexPath = DocPath.getRelativeIndexPath(game.contentSerial);
  await RepeatDoc.writeFile(indexPath, map);
  RepeatDocHelp.clear();
  var segmentContent = await RepeatDocHelp.from(game.segmentKeyId);
  if (segmentContent != null) {
    await Db().db.gameDao.clearGame(reqBody.gameId, user.id!, segmentContent.aStart, segmentContent.aEnd, segmentContent.word);
  }
  await Get.find<GsCrRepeatLogic>().refreshView();
  server.broadcast(Request(path: Path.refreshGame, data: {"id": game.id, "time": game.time}));
  return message.Response();
}
