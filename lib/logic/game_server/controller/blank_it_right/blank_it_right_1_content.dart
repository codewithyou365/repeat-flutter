import 'dart:convert';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/verse_help.dart';

import 'game.dart';

class BlankItRightContentRes {
  String content;
  String step;
  String answer;
  String submit;
  int score;

  BlankItRightContentRes({
    required this.content,
    required this.step,
    required this.answer,
    required this.submit,
    required this.score,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'step': step,
      'answer': answer,
      'submit': submit,
      'score': score,
    };
  }
}

Future<message.Response?> blankItRightContent(message.Request req, GameUser user) async {
  var editorUserId = blankItRightGame.getEditorUserId();
  if (editorUserId == 0) {
    return message.Response(error: GameServerError.editorUserNeedToBeSpecified.name);
  }
  final reqBody = req.data as int;
  final verse = VerseHelp.getCache(reqBody);
  if (verse == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  final game = await Db().db.gameDao.getOne();
  if (game == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  if (editorUserId == user.getId()) {
    return message.Response(
      data: BlankItRightContentRes(
        content: verse.verseContent,
        step: blankItRightGame.getStepEnum(userId: user.getId()).name,
        answer: '',
        submit: '',
        score: 0,
      ),
    );
  } else {
    var content = '';
    var answer = '';
    var submit = '';
    var score = 0;
    final step = blankItRightGame.getStepEnum(userId: user.getId());
    switch (step) {
      case StepEnum.blanked:
        content = blankItRightGame.getBlankContent(
          verse: jsonDecode(verse.verseContent),
          focusRefresh: false,
        );
        break;
      case StepEnum.finished:
        var verseMap = jsonDecode(verse.verseContent);
        content = blankItRightGame.getBlankContent(
          verse: verseMap,
          focusRefresh: false,
        );
        answer = verseMap['a'] ?? '';
        submit = blankItRightGame.getSubmit(userId: user.getId());
        score = blankItRightGame.getScore(userId: user.getId());
        break;
      default:
        break;
    }
    return message.Response(
      data: BlankItRightContentRes(
        content: content,
        step: step.name,
        answer: answer,
        submit: submit,
        score: score,
      ),
    );
  }
}
