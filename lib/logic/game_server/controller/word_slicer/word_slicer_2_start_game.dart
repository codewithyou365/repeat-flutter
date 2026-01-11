import 'dart:async';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/game_server/controller/word_slicer/utils.dart';

import 'game.dart';

Future<message.Response?> wordSlicerStartGame(message.Request req, GameUser user, Server<GameUser> server) async {
  if (wordSlicerGame.gameStep != GameStepEnum.selectRule) {
    return message.Response(error: GameServerError.gameStateInvalid.name);
  }
  if (wordSlicerGame.userIds.isEmpty) {
    return message.Response(error: GameServerError.wordSlicerNoPlayers.name);
  }

  final text = WordSlicerUtils.getText(wordSlicerGame.verseId);
  if (text == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }

  wordSlicerGame.gameStep = GameStepEnum.started;
  wordSlicerGame.currUserIndex = 0;
  wordSlicerGame.maxScore = await WordSlicerUtils.getMaxScore();
  wordSlicerGame.hiddenContentPercent = await WordSlicerUtils.getHiddenContentPercent();
  wordSlicerGame.setForNewGame(text);

  server.broadcast(message.Request(path: Path.wordSlicerStatusUpdate, data: wordSlicerGame.toJson()));
  return message.Response();
}
