import 'dart:convert';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/verse_help.dart';

import 'step.dart';
import 'utils.dart';

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
  var editorId = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForEditorUserId);
  if (editorId == null) {
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
  if (editorId == user.getId()) {
    return message.Response(
      data: BlankItRightContentRes(
        content: verse.verseContent,
        step: Step.getStepEnum(userId: user.getId()).name,
        answer: '',
        submit: '',
        score: 0,
      ),
    );
  } else {
    var content = '';
    var answer = '';
    var submit = '';
    final step = Step.getStepEnum(userId: user.getId());
    switch (step) {
      case StepEnum.blanked:
        content = BlankItRightUtils.getBlank(jsonDecode(verse.verseContent));
        break;
      case StepEnum.finished:
        var verseMap = jsonDecode(verse.verseContent);
        content = BlankItRightUtils.getBlank(verseMap);
        answer = verseMap['a'] ?? '';
        submit = Step.getSubmit(userId: user.getId());
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
        score: 9999,
      ),
    );
  }
}
