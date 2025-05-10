import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/common/ws/message.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/game.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/game_server/web_server.dart';
import 'package:repeat_flutter/logic/model/segment_show.dart';
import 'package:repeat_flutter/logic/segment_help.dart';

class GameHelper {
  final WebServer server;

  GameHelper(this.server);

  Future<void> tryRefreshGame(SegmentTodayPrg stp) async {
    if (!server.open) {
      return;
    }
    SegmentShow segment = SegmentHelp.getCache(stp.segmentKeyId)!;
    var now = DateTime.now();
    stp.time += 1;
    var game = Game(
      id: stp.id!,
      time: stp.time,
      segmentContent: segment.segmentContent,
      segmentKeyId: segment.segmentKeyId,
      classroomId: stp.classroomId,
      contentSerial: segment.contentSerial,
      lessonIndex: segment.lessonIndex,
      segmentIndex: segment.segmentIndex,
      finish: false,
      createTime: now.millisecondsSinceEpoch,
      createDate: Date.from(now),
    );
    await Db().db.gameDao.tryInsertGame(game);
    await server.server.broadcast(Request(path: Path.refreshGame, data: {"id": stp.id, "time": stp.time}));
  }
}
