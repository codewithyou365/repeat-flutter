import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';

import 'model/segment_show.dart';

class SegmentHelp {
  static List<SegmentShow> cache = [];
  static Map<int, SegmentShow> segmentKeyIdToShow = {};

  static Future<String> getSegmentKey(int classroomId) async {
    var progressUpdateTime = await Db().db.scheduleDao.stringKv(Classroom.curr, CrK.updateSegmentShowTime) ?? '';
    var contentUpdateTime = await Db().db.scheduleDao.getMaxContentUpdateTime(Classroom.curr) ?? 0;
    return '$progressUpdateTime-$contentUpdateTime';
  }

  static tryGen({force = false}) async {
    if (cache.isEmpty || force) {
      cache = await Db().db.scheduleDao.getAllSegment(Classroom.curr);
      segmentKeyIdToShow = {for (var segment in cache) segment.segmentKeyId: segment};
    }
  }

  static Future<List<SegmentShow>> getSegments() async {
    await tryGen();
    return cache;
  }

  static SegmentShow? getCache(int segmentKeyId) {
    return SegmentHelp.segmentKeyIdToShow[segmentKeyId];
  }

  static String getSegmentPos(int segmentKeyId) {
    var segment = SegmentHelp.segmentKeyIdToShow[segmentKeyId];
    if (segment != null) {
      return "${segment.toLessonPos()}${segment.toSegmentPos()}";
    }
    return "";
  }

  static void deleteCache(int segmentKeyId) {
    cache.removeWhere((element) => element.segmentKeyId == segmentKeyId);
    segmentKeyIdToShow.remove(segmentKeyId);
  }
}
