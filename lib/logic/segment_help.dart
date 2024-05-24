import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

class SegmentHelp {
  static Map<String, RepeatDoc> indexDocPathToQa = {};
  static Map<String, List<MediaSegment>> mediaDocPathToMediaSegments = {};
  static Map<int, SegmentContent> scheduleKeyToLearnSegment = {};

  static clear() {
    indexDocPathToQa = {};
    mediaDocPathToMediaSegments = {};
    scheduleKeyToLearnSegment = {};
  }

  static Future<SegmentContent?> from(int segmentKeyId) async {
    if (scheduleKeyToLearnSegment.containsKey(segmentKeyId)) {
      return scheduleKeyToLearnSegment[segmentKeyId]!;
    }
    var retInDb = await Db().db.scheduleDao.getSegmentContent(segmentKeyId);
    if (retInDb == null) {
      return null;
    }
    var ret = SegmentContent.from(retInDb);
    var qa = indexDocPathToQa[ret.indexDocPath];
    if (qa == null) {
      qa = await RepeatDoc.fromPath(ret.indexDocPath, Uri.parse(ret.indexDocUrl));
      if (qa == null) {
        return null;
      }
      indexDocPathToQa[ret.indexDocPath] = qa;
    }

    var lesson = qa.lesson[ret.lessonIndex];
    // full title, prevQa and qa
    {
      ret.title = lesson.title;
      var segment = lesson.segment[ret.segmentIndex];
      if (ret.segmentIndex != 0) {
        var prevSegment = lesson.segment[ret.segmentIndex - 1];
        ret.prevQuestion = prevSegment.q;
        ret.prevAnswer = prevSegment.a;
      }
      ret.question = segment.q;
      ret.tip = segment.tip;
      ret.answer = segment.a;
    }

    // full mediaSegments
    if (ret.mediaDocPath != "") {
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

    scheduleKeyToLearnSegment[segmentKeyId] = ret;
    return ret;
  }
}
