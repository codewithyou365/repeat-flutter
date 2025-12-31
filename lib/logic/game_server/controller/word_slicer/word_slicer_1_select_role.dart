import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

import 'game.dart';

Future<message.Response?> wordSlicerSelectRole(message.Request req, GameUser user, Server<GameUser> server) async {
  if (wordSlicerGame.gameStep != GameStepEnum.selectRule) {
    return message.Response(error: GameServerError.gameStateInvalid.name);
  }
  int userId = user.id!;

  for (var usersInColor in wordSlicerGame.colorIndexToUserId) {
    usersInColor.removeWhere((id) => id == userId);
  }

  int? colorIndex = req.data['index'];
  if (colorIndex != null && colorIndex >= 0 && colorIndex < wordSlicerGame.colorIndexToUserId.length) {
    wordSlicerGame.colorIndexToUserId[colorIndex].add(userId);
  }
  wordSlicerGame.userIds.removeWhere((id) => id == userId);
  wordSlicerGame.userIds.add(userId);

  wordSlicerGame.userIdToUserName['$userId'] = user.name;

  server.broadcast(message.Request(path: Path.wordSlicerStatusUpdate, data: wordSlicerGame.toJson()));

  return message.Response();
}
