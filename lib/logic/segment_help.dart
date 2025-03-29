import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';

import 'model/segment_show.dart';

class SegmentHelp {
  static String cacheKey = '';
  static List<SegmentShow> cache = [];

  static String allCacheKey = '';
  static List<SegmentShow> allCache = [];

  static Future<String> getSegmentKey(int classroomId) async {
    var progressUpdateTime = await Db().db.scheduleDao.stringKv(Classroom.curr, CrK.updateProgressTime) ?? '';
    var contentUpdateTime = await Db().db.scheduleDao.getMaxContentUpdateTime(Classroom.curr) ?? 0;
    return '$progressUpdateTime-$contentUpdateTime';
  }

  static Future<List<SegmentShow>> getAllSegment() async {
    var key = await getSegmentKey(Classroom.curr);
    if (allCacheKey != key) {
      allCacheKey = key;
      allCache = await Db().db.scheduleDao.getAllSegment(Classroom.curr);
    }
    return allCache;
  }

  static Future<List<SegmentShow>> getSegment() async {
    var key = await getSegmentKey(Classroom.curr);
    if (cacheKey != key) {
      cacheKey = key;
      cache = await Db().db.scheduleDao.getSegment(Classroom.curr);
    }
    return cache;
  }
}
