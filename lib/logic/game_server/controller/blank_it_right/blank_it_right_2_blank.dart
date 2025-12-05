import 'dart:convert';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/game_server/controller/blank_it_right/step.dart';
import 'package:repeat_flutter/logic/verse_help.dart';

import 'constant.dart';

class BlankItRightBlankReq {
  int verseId;
  String content;
  bool clearBeforeAdd;

  BlankItRightBlankReq({
    required this.verseId,
    required this.content,
    required this.clearBeforeAdd,
  });

  Map<String, dynamic> toJson() {
    return {
      'verseId': verseId,
      'content': content,
      'clearBeforeAdd': clearBeforeAdd,
    };
  }

  factory BlankItRightBlankReq.fromJson(Map<String, dynamic> json) {
    return BlankItRightBlankReq(
      verseId: json['verseId'] as int,
      content: json['content'] as String,
      clearBeforeAdd: json['clearBeforeAdd'] as bool,
    );
  }
}

bool finishBlank = false;

Future<message.Response?> blankItRightBlank(message.Request req, GameUser user, Server<GameUser> server) async {
  var userId = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForEditorUserId);
  if (userId == null) {
    return message.Response(error: GameServerError.editorUserNeedToBeSpecified.name);
  }
  if (userId != user.getId()) {
    return message.Response(error: GameServerError.editorUserInvalid.name);
  }
  if (Step.getStepEnum(userId: user.getId()) != StepEnum.blanking) {
    return message.Response(error: GameServerError.gameStateInvalid.name);
  }
  final reqBody = BlankItRightBlankReq.fromJson(req.data);
  final verseId = reqBody.verseId;
  final verse = VerseHelp.getCache(verseId);
  if (verse == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  var verseMap = jsonDecode(verse.verseContent);

  List<String> blankItRightList = [];
  if (verseMap[MapKeyEnum.blankItRightList.name] != null) {
    var temp = verseMap[MapKeyEnum.blankItRightList.name] as List<dynamic>;
    for (var t in temp) {
      blankItRightList.add(t.toString());
    }
  }
  var blankItRightUsingIndex = -1;
  if (verseMap[MapKeyEnum.blankItRightUsingIndex.name] != null) {
    var temp = verseMap[MapKeyEnum.blankItRightUsingIndex.name] as int;
    blankItRightUsingIndex = temp;
  }
  var needToUpdate = true;
  for (int i = 0; i < blankItRightList.length; i++) {
    var content = blankItRightList[i];
    if (reqBody.content == content) {
      if (blankItRightUsingIndex != i) {
        verseMap[MapKeyEnum.blankItRightUsingIndex.name] = i;
      } else {
        needToUpdate = false;
        break;
      }
    }
  }
  if (needToUpdate) {
    if (reqBody.clearBeforeAdd) {
      verseMap[MapKeyEnum.blankItRightList.name] = [reqBody.content];
    } else {
      blankItRightList.add(reqBody.content);
      verseMap[MapKeyEnum.blankItRightList.name] = blankItRightList;
    }
    final jsonStr = jsonEncode(verseMap);
    await Db().db.verseDao.updateVerseContent(verseId, jsonStr);
  }
  final game = await Db().db.gameDao.getOne();
  if (game == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  Step.blanked();
  await server.broadcast(
    message.Request(
      path: Path.refreshGame,
      data: {
        "verseId": verseId,
      },
    ),
  );
  return message.Response(data: true);
}
