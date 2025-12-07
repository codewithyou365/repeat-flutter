import 'dart:convert';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/game_user_score.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/verse_help.dart';

import 'step.dart';
import 'utils.dart';

class BlankItRightSubmitReq {
  int verseId;
  String content;

  BlankItRightSubmitReq({
    required this.verseId,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'verseId': verseId,
      'content': content,
    };
  }

  factory BlankItRightSubmitReq.fromJson(Map<String, dynamic> json) {
    return BlankItRightSubmitReq(
      verseId: json['verseId'] as int,
      content: json['content'] as String,
    );
  }
}

class BlankItRightSubmitRes {
  int score;
  String answer;

  BlankItRightSubmitRes({
    required this.score,
    required this.answer,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'answer': answer,
    };
  }

  factory BlankItRightSubmitRes.fromJson(Map<String, dynamic> json) {
    return BlankItRightSubmitRes(
      score: json['score'] as int,
      answer: json['answer'] as String,
    );
  }
}

Future<message.Response?> blankItRightSubmit(message.Request req, GameUser user, Server<GameUser> server) async {
  var userId = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForEditorUserId);
  if (userId == null) {
    return message.Response(error: GameServerError.editorUserNeedToBeSpecified.name);
  }
  if (userId == user.getId()) {
    return message.Response(error: GameServerError.submitUserInvalid.name);
  }
  if (Step.getStepEnum(userId: user.getId()) != StepEnum.blanked) {
    return message.Response(error: GameServerError.gameStateInvalid.name);
  }
  final reqBody = BlankItRightSubmitReq.fromJson(req.data);
  final verseId = reqBody.verseId;
  final verse = VerseHelp.getCache(verseId);
  if (verse == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  var verseMap = jsonDecode(verse.verseContent);
  final String userAnswer = reqBody.content;
  final String correctAnswer = verseMap['a'] ?? '';
  final String blank = BlankItRightUtils.getBlank(verseMap);
  final int maxScore = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForMaxScore) ?? 10;
  final int currScore = BlankItRightUtils.getScore(userAnswer, correctAnswer, blank, maxScore);
  Step.finished(userId: user.getId(), submit: reqBody.content, score: currScore);
  await Db().db.gameUserScoreDao.inc(userId, GameType.blankItRight, currScore, "i:${I18nKey.obtainedInTheGame.name}");
  return message.Response(
    data: BlankItRightSubmitRes(
      score: currScore,
      answer: correctAnswer,
    ),
  );
}
