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
  List<int> selectedIndexed = List<int>.from(req.data);
  if (wordSlicerGame.userIds.length > 1) {
    final isConsecutive = selectedIndexed.asMap().entries.every((entry) {
      final i = entry.key;
      final val = entry.value;
      if (i == 0) return true;
      return val == selectedIndexed[i - 1] + 1;
    });

    if (!isConsecutive) {
      return message.Response(error: GameServerError.wordSlicerYourCommitMustBeConsecutive.name);
    }
  }

  int colorIndex = wordSlicerGame.getColorIndex(user.getId());
  if (selectedIndexed.isEmpty) {
    wordSlicerGame.abandonUserIds[user.getId()] = true;
  } else {
    wordSlicerGame.abandonUserIds.remove(user.getId());
  }

  wordSlicerGame.colorIndexToSelectedContentIndex[colorIndex].addAll(selectedIndexed);

  final contentChars = wordSlicerGame.content.split('');
  final originChars = wordSlicerGame.originContent.split('');
  for (final index in selectedIndexed) {
    if (index >= 0 && index < contentChars.length) {
      contentChars[index] = originChars[index];
    }
  }
  wordSlicerGame.content = contentChars.join();

  bool selectedAll = wordSlicerGame.isSelectedAll();
  if (selectedAll || wordSlicerGame.abandonUserIds.length == wordSlicerGame.userIds.length) {
    wordSlicerGame.gameStep = GameStepEnum.finished;
    wordSlicerGame.answer = wordSlicerGame.originContentWithSpace;
    wordSlicerGame.content = wordSlicerGame.originContent;
    wordSlicerGame.setResult();
    for (final entry in wordSlicerGame.userIdToScore.entries) {
      final userId = entry.key;
      final score = entry.value;
      final remark = score > 0 ? "i:${I18nKey.obtainedInTheGame.name}" : "i:${I18nKey.deductedInTheGame.name}";
      await Db().db.gameUserScoreDao.inc(int.parse(userId), GameType.wordSlicer, score, remark);
    }
  }

  wordSlicerGame.nextUser();

  server.broadcast(message.Request(path: Path.wordSlicerStatusUpdate, data: wordSlicerGame.toJson()));
  return message.Response();
}
