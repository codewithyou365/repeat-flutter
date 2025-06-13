import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/database.dart' show Db;
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/time_stats.dart';

class TimeStatsLogic {
  int lastRecallTime = 0;

  tryInsertTimeStats() async {
    var now = DateTime.now();
    var nowMs = now.millisecondsSinceEpoch;
    lastRecallTime = nowMs;
    await Db().db.statsDao.tryInsertTimeStats(TimeStats(Classroom.curr, Date.from(now), nowMs, 0));
  }

  updateTimeStats() {
    var now = DateTime.now();
    var nowMs = now.millisecondsSinceEpoch;
    var duration = nowMs - lastRecallTime;
    if (duration > 2000) {
      if (duration > 60000) {
        duration = 60000;
      }
      lastRecallTime = nowMs;
      Db().db.statsDao.updateTimeStats(Classroom.curr, Date.from(now), duration);
    }
  }
}
