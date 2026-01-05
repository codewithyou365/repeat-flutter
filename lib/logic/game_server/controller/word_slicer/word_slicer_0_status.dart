import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/entity/game_user.dart';

import 'game.dart';
import 'utils.dart';

Future<message.Response?> wordSlicerStatus(message.Request req, GameUser user) async {
  return message.Response(
    data: wordSlicerGame.toJson(),
    headers: await WordSlicerUtils.getHeaders(user.getId()),
  );
}
