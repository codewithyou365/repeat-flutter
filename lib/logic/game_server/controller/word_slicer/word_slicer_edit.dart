import 'dart:convert';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/verse_help.dart';

import 'constant.dart';
import 'game.dart';

Future<message.Response?> wordSlicerEdit(message.Request req, GameUser user, Server<GameUser> server) async {
  if (wordSlicerGame.gameStep == GameStepEnum.finished) {
    return message.Response(error: GameServerError.gameStateInvalid.name);
  }
  var userId = await Db().db.crKvDao.getInt(Classroom.curr, CrK.wordSlicerGameForEditorUserId);
  if (userId == null) {
    return message.Response(error: GameServerError.editorUserNeedToBeSpecified.name);
  }
  if (userId != user.getId()) {
    return message.Response(error: GameServerError.editorUserInvalid.name);
  }
  var verseId = wordSlicerGame.verseId;
  final verse = VerseHelp.getCache(verseId);
  if (verse == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  var verseMap = jsonDecode(verse.verseContent);

  String wordSlicerText = '';
  if (verseMap[MapKeyEnum.wordSlicerText.name] != null) {
    wordSlicerText = verseMap[MapKeyEnum.wordSlicerText.name] as String;
  }
  String reqWordSlicerText = req.data as String;
  if (wordSlicerText != reqWordSlicerText) {
    verseMap[MapKeyEnum.wordSlicerText.name] = reqWordSlicerText;
    final jsonStr = jsonEncode(verseMap);
    await Db().db.verseDao.updateVerseContent(verseId, jsonStr);
  }
  final game = await Db().db.gameDao.getOne();
  if (game == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  await server.broadcast(
    message.Request(
      path: Path.refreshGame,
      data: {
        "verseId": verseId,
      },
    ),
  );
  return message.Response();
}
