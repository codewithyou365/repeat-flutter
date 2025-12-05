import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/common/ws/message.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/game_server/web_server.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/verse_help.dart';

class GameHelper {
  final WebServer server;

  GameHelper(this.server);

  Future<void> tryRefreshGame(VerseTodayPrg stp) async {
    if (!server.open) {
      return;
    }
    VerseShow verse = VerseHelp.getCache(stp.verseId)!;
    var now = DateTime.now();
    stp.time += 1;
    var game = Game(
      id: stp.id!,
      time: stp.time,
      verseContent: verse.verseContent,
      verseId: verse.verseId,
      classroomId: stp.classroomId,
      bookId: verse.bookId,
      chapterId: verse.chapterId,
      finish: false,
      createTime: now.millisecondsSinceEpoch,
      createDate: Date.from(now),
    );
    await Db().db.gameDao.tryInsertGame(game);
    EventBus().publish(EventTopic.newGame, game);
    await server.server.broadcast(
      Request(
        path: Path.refreshGame,
        data: {
          "id": stp.id,
          "time": stp.time,
          "verseId": stp.verseId,
        },
      ),
    );
  }
}
