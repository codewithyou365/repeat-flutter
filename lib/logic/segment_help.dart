import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/model/qa_repeat_file.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

class SegmentHelp {
  static Map<String, QaRepeatFile> indexFilePathToKv = {};
  static Map<String, List<MediaSegment>> mediaFilePathToMediaSegments = {};
  static Map<String, SegmentContent> scheduleKeyToLearnSegment = {};

  static clear() {
    indexFilePathToKv = {};
    mediaFilePathToMediaSegments = {};
    scheduleKeyToLearnSegment = {};
  }

  static Future<SegmentContent?> from(String scheduleKey) async {
    if (scheduleKeyToLearnSegment.containsKey(scheduleKey)) {
      return scheduleKeyToLearnSegment[scheduleKey]!;
    }
    var retInDb = await Db().db.scheduleDao.getSegmentContent(scheduleKey);
    if (retInDb == null) {
      return null;
    }
    var ret = SegmentContent.from(retInDb);
    var kv = indexFilePathToKv[ret.indexFilePath];
    if (kv == null) {
      kv = await QaRepeatFile.fromFile(ret.indexFilePath, Uri.parse(ret.indexFileUrl));
      indexFilePathToKv[ret.indexFilePath] = kv;
    }

    var lesson = kv.lesson[ret.lessonIndex];
    // full qa
    {
      var segment = lesson.segment[ret.segmentIndex];

      ret.question = segment.q;
      ret.answer = segment.a;
    }

    // full mediaSegments
    {
      var mediaSegments = mediaFilePathToMediaSegments[ret.mediaFilePath];
      if (mediaSegments == null) {
        mediaSegments = [];
        for (var s in lesson.segment) {
          mediaSegments.add(MediaSegment.from(s.start, s.end));
        }
        mediaFilePathToMediaSegments[ret.mediaFilePath] = mediaSegments;
      }
      ret.mediaSegments = mediaSegments;
    }

    scheduleKeyToLearnSegment[scheduleKey] = ret;
    return ret;
  }
}
