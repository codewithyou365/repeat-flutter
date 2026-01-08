import 'dart:convert';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/game_server/controller/blank_it_right/game.dart';
import 'package:repeat_flutter/logic/verse_help.dart';

import 'constant.dart';

class BlankItRightBlankReq {
  int verseId;
  String content;

  BlankItRightBlankReq({
    required this.verseId,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'verseId': verseId,
      'content': content,
    };
  }

  factory BlankItRightBlankReq.fromJson(Map<String, dynamic> json) {
    return BlankItRightBlankReq(
      verseId: json['verseId'] as int,
      content: json['content'] as String,
    );
  }
}

bool finishBlank = false;

Future<message.Response?> blankItRightBlank(message.Request req, GameUser user, Server<GameUser> server) async {
  var editorUserId = blankItRightGame.getEditorUserId();
  if (editorUserId == 0) {
    return message.Response(error: GameServerError.editorUserNeedToBeSpecified.name);
  }
  if (editorUserId != user.getId()) {
    return message.Response(error: GameServerError.editorUserInvalid.name);
  }
  if (!blankItRightGame.autoBlank && blankItRightGame.getStepEnum(userId: user.getId()) != StepEnum.blanking) {
    return message.Response(error: GameServerError.gameStateInvalid.name);
  }
  final reqBody = BlankItRightBlankReq.fromJson(req.data);
  final verseId = reqBody.verseId;
  final verse = VerseHelp.getCache(verseId);
  if (verse == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  var verseMap = jsonDecode(verse.verseContent);

  String blankItRightText = '';
  if (verseMap[MapKeyEnum.blankItRightText.name] != null) {
    blankItRightText = verseMap[MapKeyEnum.blankItRightText.name] as String;
  }
  if (reqBody.content != blankItRightText) {
    verseMap[MapKeyEnum.blankItRightText.name] = reqBody.content;
    final jsonStr = jsonEncode(verseMap);
    await Db().db.verseDao.updateVerseContent(verseId, jsonStr);
  }
  blankItRightGame.blanked();
  blankItRightGame.getBlankContent(
    verse: verseMap,
    focusRefresh: true,
  );
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
