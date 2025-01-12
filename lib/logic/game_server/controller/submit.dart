import 'dart:convert';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/game_user_input.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

class SubmitReq {
  int gameId;
  int prevId;
  String input;

  SubmitReq(this.gameId, this.prevId, this.input);

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'prevId': prevId,
      'input': input,
    };
  }

  factory SubmitReq.fromJson(Map<String, dynamic> json) {
    return SubmitReq(
      json['gameId'] as int,
      json['prevId'] as int,
      json['input'] as String,
    );
  }
}

class SubmitRes {
  int id;
  List<String> input;
  List<String> output;

  SubmitRes(this.id, this.input, this.output);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'input': input,
      'output': output,
    };
  }

  factory SubmitRes.fromJson(Map<String, dynamic> json) {
    return SubmitRes(
      json['id'] as int,
      List<String>.from(json['input'] ?? []),
      List<String>.from(json['output'] ?? []),
    );
  }
}

Future<message.Response?> submit(message.Request req, GameUser? user) async {
  if (user == null) {
    return message.Response(error: GameServerError.serviceStopped.name);
  }
  final reqBody = SubmitReq.fromJson(req.data);
  final game = await Db().db.gameDao.one(reqBody.gameId);
  if (game == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  List<String> input = [];
  List<String> output = [];
  GameUserInput? gameUserInput = await Db().db.gameDao.submit(game, reqBody.prevId, user.id!, reqBody.input, input, output);
  if (gameUserInput == null) {
    return message.Response(error: GameServerError.gameSyncError.name);
  }
  final res = SubmitRes(gameUserInput.id!, input, output);
  return message.Response(data: res);
}
