import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';

import 'model/segment_show.dart';

class SegmentShowHelp {
  static int lastMaxTime = 0;
  static List<SegmentShow> cache = [];

  static int lastAllMaxTime = 0;
  static List<SegmentShow> allCache = [];

  static Future<List<SegmentShow>> getAllSegment() async {
    var currMaxTime = await Db().db.scheduleDao.getMaxSegmentStats(Classroom.curr) ?? 0;
    if (currMaxTime > lastAllMaxTime) {
      lastAllMaxTime = currMaxTime;
      allCache = await Db().db.scheduleDao.getAllSegment(Classroom.curr);
    }
    return allCache;
  }

  static Future<List<SegmentShow>> getSegment() async {
    var currMaxTime = await Db().db.scheduleDao.getMaxSegmentStats(Classroom.curr) ?? 0;
    if (currMaxTime > lastMaxTime) {
      lastMaxTime = currMaxTime;
      cache = await Db().db.scheduleDao.getSegment(Classroom.curr);
    }
    return cache;
  }
}
