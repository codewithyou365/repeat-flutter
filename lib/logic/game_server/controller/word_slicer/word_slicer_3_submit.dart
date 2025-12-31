import 'dart:async';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

import 'game.dart';

Future<message.Response?> wordSlicerSubmit(message.Request req, GameUser user, Server<GameUser> server) async {
  if (wordSlicerGame.gameStep != GameStepEnum.started) {
    return message.Response(error: GameServerError.gameStateInvalid.name);
  }

  int colorIndex = wordSlicerGame.getColorIndex(user.getId());
  wordSlicerGame.colorIndexToSelectedContentIndex[colorIndex].addAll(List<int>.from(req.data));
  bool selectedAll = wordSlicerGame.isSelectedAll();
  if (selectedAll) {
    wordSlicerGame.gameStep = GameStepEnum.finished;
    wordSlicerGame.colorIndexToScore = wordSlicerGame.getColorIndexToScore();
  } else {
    wordSlicerGame.nextUser();
  }

  server.broadcast(message.Request(path: Path.wordSlicerStatusUpdate, data: wordSlicerGame.toJson()));
  return message.Response();
}
