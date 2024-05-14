import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/logic/model/qa_repeat_doc.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

class SegmentHelp {
  static Map<String, QaRepeatDoc> indexDocPathToQa = {};
  static Map<String, List<MediaSegment>> mediaDocPathToMediaSegments = {};
  static Map<String, SegmentContent> scheduleKeyToLearnSegment = {};

  static clear() {
    indexDocPathToQa = {};
    mediaDocPathToMediaSegments = {};
    scheduleKeyToLearnSegment = {};
  }

  static Future<SegmentContent?> from(String scheduleKey) async {
    if (scheduleKeyToLearnSegment.containsKey(scheduleKey)) {
      return scheduleKeyToLearnSegment[scheduleKey]!;
    }
    var retInDb = await Db().db.scheduleDao.getSegmentContent(Classroom.curr, scheduleKey);
    if (retInDb == null) {
      return null;
    }
    var ret = SegmentContent.from(retInDb);
    var qa = indexDocPathToQa[ret.indexDocPath];
    if (qa == null) {
      qa = await QaRepeatDoc.fromPath(ret.indexDocPath, Uri.parse(ret.indexDocUrl));
      if (qa == null) {
        return null;
      }
      indexDocPathToQa[ret.indexDocPath] = qa;
    }

    var lesson = qa.lesson[ret.lessonIndex];
    // full qa
    {
      var segment = lesson.segment[ret.segmentIndex];

      ret.question = segment.q;
      ret.answer = segment.a;
    }

    // full mediaSegments
    {
      var mediaSegments = mediaDocPathToMediaSegments[ret.mediaDocPath];
      if (mediaSegments == null) {
        mediaSegments = [];
        for (var s in lesson.segment) {
          mediaSegments.add(MediaSegment.from(s.start, s.end));
        }
        mediaDocPathToMediaSegments[ret.mediaDocPath] = mediaSegments;
      }
      ret.mediaSegments = mediaSegments;
    }

    scheduleKeyToLearnSegment[scheduleKey] = ret;
    return ret;
  }
}
