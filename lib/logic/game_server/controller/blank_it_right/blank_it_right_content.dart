import 'dart:convert';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/verse_help.dart';

import 'constant.dart';

Future<message.Response?> blankItRightContent(message.Request req, GameUser user) async {
  var userId = await Db().db.crKvDao.getInt(Classroom.curr, CrK.blockItRightGameForEditorUserId);
  if (userId == null) {
    return message.Response(error: GameServerError.editorUserNeedToBeSpecified.name);
  }
  final reqBody = req.data as int;
  final verse = VerseHelp.getCache(reqBody);
  if (verse == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  if (userId == user.getId()) {
    return message.Response(data: verse.verseContent);
  } else {
    var verseMap = jsonDecode(verse.verseContent);
    if (verseMap[MapKeyEnum.blankItRightList.name] == null || verseMap[MapKeyEnum.blankItRightUsingIndex.name] == null) {
      return message.Response(error: GameServerError.gameNotReady.name);
    }
    final blankItRightList = verseMap[MapKeyEnum.blankItRightList.name] as List<String>;
    final blankItRightUsingIndex = verseMap[MapKeyEnum.blankItRightUsingIndex.name] as int;
    return message.Response(data: blankItRightList[blankItRightUsingIndex]);
  }
}
