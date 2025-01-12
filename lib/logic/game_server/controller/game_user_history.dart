import 'dart:convert';

import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

import 'submit.dart';

class GameUserHistoryReq {
  int gameId;
  int time;

  GameUserHistoryReq(
    this.gameId,
    this.time,
  );

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'time': time,
    };
  }

  factory GameUserHistoryReq.fromJson(Map<String, dynamic> json) {
    return GameUserHistoryReq(
      json['gameId'] as int,
      json['time'] as int,
    );
  }
}

class GameUserHistoryRes {
  List<SubmitRes> list;

  GameUserHistoryRes(this.list);

  Map<String, dynamic> toJson() {
    return {
      'list': list,
    };
  }

  factory GameUserHistoryRes.fromJson(Map<String, dynamic> json) {
    return GameUserHistoryRes(
      List<SubmitRes>.from(json['list'].map((dynamic d) => SubmitRes.fromJson(d))),
    );
  }
}

Future<message.Response?> gameUserHistory(message.Request req, GameUser? user) async {
  if (user == null) {
    return message.Response(error: GameServerError.serviceStopped.name);
  }
  final reqBody = GameUserHistoryReq.fromJson(req.data);
  final gus = await Db().db.gameDao.gameUserInput(reqBody.gameId, user.id!, reqBody.time);
  GameUserHistoryRes res = GameUserHistoryRes([]);
  for (final gu in gus) {
    res.list.add(SubmitRes(gu.id!, ListUtil.toList(gu.input), ListUtil.toList(gu.output)));
  }
  return message.Response(data: res);
}
