import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/game_server/web_server.dart';
import 'package:repeat_flutter/logic/tip_server/web_server.dart';

class SessionCoordinator {
  final WebServer gameServer;
  final TipWebServer tipServer;

  SessionCoordinator(this.gameServer, this.tipServer);

  Future<void> tryRefresh(VerseTodayPrg stp) async {
    if (gameServer.open || tipServer.open) {
      await Db().db.kvDao.insertOrReplace(Kv(K.lastVerseId, '${stp.verseId}'));
      stp.time += 1;
      EventBus().publish(EventTopic.newVerse, stp.verseId);
    }
  }
}
