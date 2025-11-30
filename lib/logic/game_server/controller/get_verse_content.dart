import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/verse_help.dart';

class GetVerseContentReq {
  int verseId;

  GetVerseContentReq(this.verseId);

  Map<String, dynamic> toJson() {
    return {
      'verseId': verseId,
    };
  }

  factory GetVerseContentReq.fromJson(Map<String, dynamic> json) {
    return GetVerseContentReq(
      json['verseId'] as int,
    );
  }
}

class GetVerseContentRes {
  String content;

  GetVerseContentRes(this.content);

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }

  factory GetVerseContentRes.fromJson(Map<String, dynamic> json) {
    return GetVerseContentRes(
      json['content'] as String,
    );
  }
}

Future<message.Response?> getVerseContent(message.Request req, GameUser? user) async {
  if (user == null) {
    return message.Response(error: GameServerError.serviceStopped.name);
  }
  final reqBody = GetVerseContentReq.fromJson(req.data);
  final verse = VerseHelp.getCache(reqBody.verseId);
  if (verse == null) {
    return message.Response(error: GameServerError.gameNotFound.name);
  }
  final res = GetVerseContentRes(verse.verseContent);
  return message.Response(data: res);
}
