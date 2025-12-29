import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/entity/game_user.dart';

import 'game.dart';

Future<message.Response?> wordSlicerStatus(message.Request req, GameUser user) async {
  return message.Response(data: wordSlicerGame.toJson());
}
