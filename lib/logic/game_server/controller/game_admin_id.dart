import 'dart:async';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';


import 'package:repeat_flutter/logic/widget/game/game_state.dart';

Future<message.Response?> gameAdminId(
  message.Request req,
  GameUser user,
) async {
  if (GameState.game == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  return message.Response(data: GameState.adminId);
}
