import 'package:get/get.dart';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/game_user_input.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/gs_cr_repeat_logic.dart';

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
  int matchType;

  SubmitRes(this.id, this.input, this.output, this.matchType);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'input': input,
      'output': output,
      'matchType': matchType,
    };
  }

  factory SubmitRes.fromJson(Map<String, dynamic> json) {
    return SubmitRes(
      json['id'] as int,
      List<String>.from(json['input'] ?? []),
      List<String>.from(json['output'] ?? []),
      json['matchType'] as int,
    );
  }
}

Future<message.Response?> submit(message.Request req, GameUser? user) async {
  if (user == null) {
    return message.Response(error: GameServerError.serviceStopped.name);
  }
  final reqBody = SubmitReq.fromJson(req.data);
  int matchTypeInt = await Db().db.gameDao.intKv(Classroom.curr, CrK.matchTypeInTypingGame) ?? 1;
  List<String> input = [];
  List<String> output = [];
  GameUserInput gameUserInput = await Db().db.gameDao.submit(reqBody.gameId, matchTypeInt, reqBody.prevId, user.id!, reqBody.input, input, output);
  if (gameUserInput.isEmpty()) {
    return message.Response(error: GameServerError.gameSyncError.name);
  }
  final res = SubmitRes(gameUserInput.id!, input, output, matchTypeInt);
  return message.Response(data: res);
}
