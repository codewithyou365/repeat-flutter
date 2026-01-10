import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/game_server/controller/blank_it_right/game.dart';
import 'package:repeat_flutter/logic/game_server/vo/kv_list.dart';
import 'package:repeat_flutter/logic/game_server/vo/kv.dart';

import 'utils.dart';

Future<message.Response?> blankItRightSettings(message.Request req, GameUser user) async {
  var editorUserId = blankItRightGame.getEditorUserId();
  if (editorUserId == 0) {
    return message.Response(error: GameServerError.editorUserNeedToBeSpecified.name);
  }
  blankItRightGame.tryJoin(userId: user.getId());
  var ignorePunctuation = await BlankItRightUtils.getIgnorePunctuation();
  var ignoreCase = await BlankItRightUtils.getIgnoreCase();
  var res = KvList([]);
  res.list.add(Kv(k: CrK.blockItRightGameForEditorUserId.name, v: "$editorUserId"));
  res.list.add(Kv(k: CrK.blockItRightGameForIgnorePunctuation.name, v: "$ignorePunctuation"));
  res.list.add(Kv(k: CrK.blockItRightGameForIgnoreCase.name, v: "$ignoreCase"));
  return message.Response(data: res);
}
