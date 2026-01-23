import 'package:repeat_flutter/common/ws/message.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/game_server/web_server.dart';

class GameHelper {
  final WebServer server;

  GameHelper(this.server);

  Future<void> tryRefreshGame(VerseTodayPrg stp) async {
    if (!server.open) {
      return;
    }
    await Db().db.kvDao.insertKv(Kv(K.lastVerseId, '${stp.verseId}'));
    stp.time += 1;
    EventBus().publish(EventTopic.newGame, stp.verseId);
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
