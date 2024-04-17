import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/model/kv.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

class LearnSegments {
  static Map<String, Kv> indexFilePathToKv = {};
  static Map<String, List<MediaSegment>> mediaFilePathToMediaSegments = {};
  static Map<String, LearnSegment> scheduleKeyToLearnSegment = {};

  static clear() {
    indexFilePathToKv = {};
    mediaFilePathToMediaSegments = {};
    scheduleKeyToLearnSegment = {};
  }

  static Future<LearnSegment?> from(String scheduleKey) async {
    if (scheduleKeyToLearnSegment.containsKey(scheduleKey)) {
      return scheduleKeyToLearnSegment[scheduleKey]!;
    }
    var dbSegment = await Db().db.scheduleDao.getSegment(scheduleKey);
    if (dbSegment == null) {
      return null;
    }
    var kv = indexFilePathToKv[dbSegment.indexFilePath];
    if (kv == null) {
      kv = await Kv.fromFile(dbSegment.indexFilePath, Uri.parse(dbSegment.indexFileUrl));
      indexFilePathToKv[dbSegment.indexFilePath] = kv;
    }
    var ret = LearnSegment();
    ret.scheduleKey = scheduleKey;
    ret.indexFilePath = dbSegment.indexFilePath;
    var lesson = kv.lesson[dbSegment.lessonIndex];
    var segment = lesson.segment[dbSegment.segmentIndex];

    ret.value = segment.value;
    ret.key = segment.key;

    ret.mediaFilePath = dbSegment.mediaFilePath;
    var mediaSegments = mediaFilePathToMediaSegments[dbSegment.mediaFilePath];
    if (mediaSegments == null) {
      mediaSegments = [];
      for (var s in lesson.segment) {
        mediaSegments.add(MediaSegment.toLine(s.start, s.end));
      }
      mediaFilePathToMediaSegments[dbSegment.mediaFilePath] = mediaSegments;
    }
    ret.mediaSegments = mediaSegments;
    ret.mediaSegmentIndex = dbSegment.segmentIndex;
    scheduleKeyToLearnSegment[scheduleKey] = ret;
    return ret;
  }
}

class LearnSegment {
  var scheduleKey = "";

  var indexFilePath = "";

  var value = "";
  var key = "";

  var mediaFilePath = "";
  List<MediaSegment> mediaSegments = [];
  var mediaSegmentIndex = 0;
}
