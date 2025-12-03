import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

import '../verse_content.dart';

Future<message.Response?> getBlankItRightVerseContent(message.Request req, GameUser user) async {
  var userId = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForEditorUserId);
  if (userId == null) {
    return message.Response(error: GameServerError.editorUserNeedToBeSpecified.name);
  }
  if (userId != user.getId()) {
    return message.Response(error: GameServerError.editorUserInvalid.name);
  }

  //TODO
  return verseContent(req, user);
}
