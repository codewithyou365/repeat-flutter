
import 'package:get/get.dart';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/gs_cr_repeat_logic.dart';

Future<message.Response?> getEditStatus(message.Request req, GameUser? user) async {
  if (user == null) {
    return message.Response(error: GameServerError.serviceStopped.name);
  }
  return message.Response(data: Get.find<GsCrRepeatLogic>().state.editInGame.value);
}
