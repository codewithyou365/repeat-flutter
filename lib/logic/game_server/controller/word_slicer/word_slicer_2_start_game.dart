import 'dart:async';
import 'dart:convert';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/verse_help.dart';

import 'game.dart';

Future<message.Response?> wordSlicerStartGame(message.Request req, GameUser user, Server<GameUser> server) async {
  if (wordSlicerGame.gameStep != GameStepEnum.selectRule) {
    return message.Response(error: GameServerError.gameStateInvalid.name);
  }
  if (wordSlicerGame.differentColorUsers() < 2) {
    return message.Response(error: GameServerError.wordSlicerDifferentColorUserCountMustBeMoreThanTwo.name);
  }
  final verse = VerseHelp.getCache(wordSlicerGame.verseId);
  if (verse == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  final verseMap = jsonDecode(verse.verseContent);
  String answer = verseMap['a'] ?? '';

  wordSlicerGame.gameStep = GameStepEnum.started;
  wordSlicerGame.setForNewGame(answer);

  server.broadcast(message.Request(path: Path.wordSlicerStatusUpdate, data: wordSlicerGame.toJson()));
  return message.Response();
}
