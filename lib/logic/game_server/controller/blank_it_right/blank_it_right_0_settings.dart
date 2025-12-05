import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/game_server/vo/kv_list.dart';
import 'package:repeat_flutter/logic/game_server/vo/kv.dart';

Future<message.Response?> blankItRightSettings(message.Request req, GameUser user) async {
  var userId = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForEditorUserId);
  if (userId == null) {
    return message.Response(error: GameServerError.editorUserNeedToBeSpecified.name);
  }
  var ignorePunctuation = false;
  var kip = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForIgnorePunctuation);
  if (kip != null) {
    ignorePunctuation = kip == 1;
  }
  var ignoreCase = false;
  var kic = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForIgnoreCase);
  if (kic != null) {
    ignoreCase = kic == 1;
  }
  var res = KvList([]);
  res.list.add(Kv(k: CrK.blockItRightGameForEditorUserId.name, v: "$userId"));
  res.list.add(Kv(k: CrK.blockItRightGameForIgnorePunctuation.name, v: "$ignorePunctuation"));
  res.list.add(Kv(k: CrK.blockItRightGameForIgnoreCase.name, v: "$ignoreCase"));
  return message.Response(data: res);
}
