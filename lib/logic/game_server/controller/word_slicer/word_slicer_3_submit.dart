import 'dart:async';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/game_user_score.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
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
    wordSlicerGame.answer = wordSlicerGame.rawContent;
    wordSlicerGame.setResult();
    for (final entry in wordSlicerGame.userIdToScore.entries) {
      final userId = entry.key;
      final score = entry.value;
      final remark = score > 0 ? "i:${I18nKey.obtainedInTheGame.name}" : "i:${I18nKey.deductedInTheGame.name}";
      await Db().db.gameUserScoreDao.inc(int.parse(userId), GameType.wordSlicer, score, remark);
    }
  } else {
    wordSlicerGame.nextUser();
  }

  server.broadcast(message.Request(path: Path.wordSlicerStatusUpdate, data: wordSlicerGame.toJson()));
  return message.Response();
}
