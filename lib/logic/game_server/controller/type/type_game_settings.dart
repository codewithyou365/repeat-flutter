import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/vo/kv_list.dart';
import 'package:repeat_flutter/logic/game_server/vo/kv.dart';

Future<message.Response?> typeGameSettings(message.Request req, GameUser user) async {
  var ignorePunctuation = false;
  var kip = await Db().db.crKvDao.getInt(Classroom.curr, CrK.typeGameForIgnorePunctuation);
  if (kip != null) {
    ignorePunctuation = kip == 1;
  }
  var ignoreCase = false;
  var kic = await Db().db.crKvDao.getInt(Classroom.curr, CrK.typeGameForIgnoreCase);
  if (kic != null) {
    ignoreCase = kic == 1;
  }
  var res = KvList([]);
  res.list.add(Kv(k: CrK.typeGameForIgnorePunctuation.name, v: "$ignorePunctuation"));
  res.list.add(Kv(k: CrK.typeGameForIgnoreCase.name, v: "$ignoreCase"));
  return message.Response(data: res);
}
