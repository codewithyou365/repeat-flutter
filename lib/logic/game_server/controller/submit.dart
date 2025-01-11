import 'dart:convert';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

class SubmitReq {
  int gameId;
  String input;

  SubmitReq(this.gameId, this.input);

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'input': input,
    };
  }

  factory SubmitReq.fromJson(Map<String, dynamic> json) {
    return SubmitReq(
      json['gameId'] as int,
      json['input'] as String,
    );
  }
}

class SubmitRes {
  List<String> input;
  List<String> output;

  SubmitRes(this.input, this.output);

  Map<String, dynamic> toJson() {
    return {
      'input': input,
      'output': output,
    };
  }

  factory SubmitRes.fromJson(Map<String, dynamic> json) {
    return SubmitRes(
      List<String>.from(json['input'] ?? []),
      List<String>.from(json['output'] ?? []),
    );
  }
}

Future<message.Response?> submit(message.Request req) async {
  final user = await Db().db.gameUserDao.loginByToken(req.headers['token'] ?? '');
  if (user .isEmpty()) {
    return message.Response(error: GameServerError.serviceStopped.name);
  }
  final reqBody = SubmitReq.fromJson(req.data);
  final game = await Db().db.gameDao.one(reqBody.gameId);
  if (game == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  List<List<String>> result = await Db().db.gameDao.submit(game, user.id!, reqBody.input);
  final res = SubmitRes(result[0], result[1]);
  return message.Response(data: jsonEncode(res.toJson()));
}
