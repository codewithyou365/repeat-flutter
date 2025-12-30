import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

import 'game.dart';

Future<message.Response?> wordSlicerStartGame(message.Request req, GameUser user, Server<GameUser> server) async {
  if (wordSlicerGame.gameStep != GameStepEnum.selectRule) {
    return message.Response(error: GameServerError.gameStateInvalid.name);
  }
  if (wordSlicerGame.judgeUserId == -1) {
    return message.Response(error: GameServerError.wordSlicerMustHaveJudge.name);
  }
  if (wordSlicerGame.userIds.length < 2) {
    return message.Response(error: GameServerError.wordSlicerUserCountMustBeMoreThanTwo.name);
  }
  wordSlicerGame.gameStep = GameStepEnum.started;
  server.broadcast(message.Request(path: Path.wordSlicerStatusUpdate, data: wordSlicerGame.toJson()));
  return message.Response();
}
