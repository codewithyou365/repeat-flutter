import 'dart:convert';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/verse_help.dart';

import 'constant.dart';
import 'step.dart';
import 'utils.dart';

class BlankItRightContentRes {
  String content;
  String step;
  String submit;

  BlankItRightContentRes({
    required this.content,
    required this.step,
    required this.submit,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'step': step,
      'submit': submit,
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
        submit: '',
      ),
    );
  } else {
    var verseMap = jsonDecode(verse.verseContent);
    if (verseMap[MapKeyEnum.blankItRightList.name] == null || verseMap[MapKeyEnum.blankItRightUsingIndex.name] == null) {
      return message.Response(error: GameServerError.gameNotReady.name);
    }
    var content = '';
    var submit = '';
    final step = Step.getStepEnum(userId: user.getId());
    if (step == StepEnum.finished) {
      content = verseMap['a'] ?? '';
      submit = Step.getSubmit(userId: user.getId());
    } else {
      content = BlankItRightUtils.getBlank(verseMap);
    }
    return message.Response(
      data: BlankItRightContentRes(
        content: content,
        step: step.name,
        submit: submit,
      ),
    );
  }
}
