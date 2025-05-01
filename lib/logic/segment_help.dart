import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';

import 'model/segment_show.dart';

class QueryLesson {
  final int contentSerial;
  final int? lessonIndex;
  final int? minLessonIndex;

  QueryLesson({
    required this.contentSerial,
    this.lessonIndex,
    this.minLessonIndex,
  });
}

class SegmentHelp {
  static List<SegmentShow> cache = [];
  static Map<int, SegmentShow> segmentKeyIdToShow = {};

  static Future<String> getSegmentKey(int classroomId) async {
    var progressUpdateTime = await Db().db.scheduleDao.stringKv(Classroom.curr, CrK.updateSegmentShowTime) ?? '';
    var contentUpdateTime = await Db().db.scheduleDao.getMaxContentUpdateTime(Classroom.curr) ?? 0;
    return '$progressUpdateTime-$contentUpdateTime';
  }

  static tryGen({force = false, QueryLesson? query}) async {
    if (cache.isEmpty || force || query != null) {
      if (query != null) {
        if (query.lessonIndex != null) {
          List<SegmentShow> lessonSegment = await Db().db.scheduleDao.getSegmentByLessonIndex(Classroom.curr, query.contentSerial, query.lessonIndex!);
          cache.removeWhere((segment) => segment.contentSerial == query.contentSerial && segment.lessonIndex == query.lessonIndex!);
          cache.addAll(lessonSegment);
        } else if (query.minLessonIndex != null) {
          List<SegmentShow> lessonSegment = await Db().db.scheduleDao.getSegmentByMinLessonIndex(Classroom.curr, query.contentSerial, query.minLessonIndex!);
          cache.removeWhere((segment) => segment.contentSerial == query.contentSerial && segment.lessonIndex >= query.minLessonIndex!);
          cache.addAll(lessonSegment);
        }
        segmentKeyIdToShow = {for (var segment in cache) segment.segmentKeyId: segment};
      } else {
        cache = await Db().db.scheduleDao.getAllSegment(Classroom.curr);
        segmentKeyIdToShow = {for (var segment in cache) segment.segmentKeyId: segment};
      }
    }
  }

  static Future<List<SegmentShow>> getSegments({force = false, QueryLesson? query}) async {
    await tryGen(force: force, query: query);
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
