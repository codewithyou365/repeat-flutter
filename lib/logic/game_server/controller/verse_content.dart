import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/verse_help.dart';

Future<message.Response?> verseContent(message.Request req, GameUser user) async {
  final reqBody = req.data as int;
  final verse = VerseHelp.getCache(reqBody);
  if (verse == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  return message.Response(data: verse.verseContent);
}
