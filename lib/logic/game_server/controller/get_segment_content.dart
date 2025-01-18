import 'dart:convert';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/repeat_doc_help.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/gs_cr_repeat_logic.dart';

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
  if (!Get.find<GsCrRepeatLogic>().state.editInGame.value) {
    return message.Response(error: GameServerError.editModeDisabled.name);
  }
  final reqBody = GetSegmentContentReq.fromJson(req.data);
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
  List<dynamic> segments = List<dynamic>.from(lessons[game.lessonIndex]['segment']);
  if (game.segmentIndex >= segments.length) {
    return message.Response(error: GameServerError.contentNotFound.name);
  }
  final res = GetSegmentContentRes(jsonEncode(segments[game.segmentIndex]));
  return message.Response(data: res);
}
