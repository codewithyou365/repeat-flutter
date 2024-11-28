import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

class RepeatDocHelp {
  static Map<String, RepeatDoc> indexDocPathToQa = {};

  static Map<String, double?> mediaDocPathToVideoMaskRatio = {};

  static Map<String, MediaSegment> mediaDocPathToTitleMediaSegment = {};
  static Map<String, List<MediaSegment>> mediaDocPathToQuestionMediaSegments = {};
  static Map<String, List<MediaSegment>> mediaDocPathToAnswerMediaSegments = {};

  static Map<int, SegmentContent> scheduleKeyToLearnSegment = {};

  static clear() {
    indexDocPathToQa = {};
    mediaDocPathToVideoMaskRatio = {};
    mediaDocPathToAnswerMediaSegments = {};
    mediaDocPathToQuestionMediaSegments = {};
    scheduleKeyToLearnSegment = {};
  }

  static double getVideoMaskRatio(String path) {
    var ret = mediaDocPathToVideoMaskRatio[path];
    if (ret != null && ret > 0) {
      return ret;
    }
    return 20;
  }

  static void setVideoMaskRatio(String path, double ratio) {
    mediaDocPathToVideoMaskRatio[path] = ratio;
  }

  static Future<SegmentContent?> from(int segmentKeyId, {int offset = 0, RxString? err}) async {
    if (offset < 0) {
      var id = await Db().db.scheduleDao.getPrevSegmentKeyIdWithOffset(Classroom.curr, segmentKeyId, offset.abs());
      if (id != null) {
        segmentKeyId = id;
      }
    } else if (offset > 0) {
      var id = await Db().db.scheduleDao.getNextSegmentKeyIdWithOffset(Classroom.curr, segmentKeyId, offset.abs());
      if (id != null) {
        segmentKeyId = id;
      }
    }
    if (scheduleKeyToLearnSegment.containsKey(segmentKeyId)) {
      return scheduleKeyToLearnSegment[segmentKeyId]!;
    }
    var retInDb = await Db().db.scheduleDao.getSegmentContent(segmentKeyId);
    if (retInDb == null) {
      return null;
    }
    var ret = SegmentContent.from(retInDb);
    var qa = await getAndCacheQa(ret, err: err);
    if (qa == null) {
      return null;
    }
    var lesson = qa.lesson[ret.lessonIndex];
    // full title, prevQa and qa
    {
      ret.title = lesson.title;
      if (ret.segmentIndex < lesson.segment.length) {
        var segment = lesson.segment[ret.segmentIndex];
        if (ret.segmentIndex != 0) {
          var prevSegment = lesson.segment[ret.segmentIndex - 1];
          ret.prevAnswer = prevSegment.a;
        }
        ret.question = segment.q;
        ret.tip = segment.tip;
        ret.answer = segment.a;
      } else {
        ret.miss = true;
      }
    }

    // full mediaSegments
    if (ret.mediaDocPath != "") {
      // for mask ratio
      var ratio = mediaDocPathToVideoMaskRatio[ret.mediaDocPath];
      if (ratio == null && lesson.videoMaskRatio != "") {
        double va = double.parse(lesson.videoMaskRatio);
        mediaDocPathToVideoMaskRatio[ret.mediaDocPath] = va;
      } else {
        mediaDocPathToVideoMaskRatio[ret.mediaDocPath] = 20;
      }

      var titleMediaSegment = mediaDocPathToTitleMediaSegment[ret.mediaDocPath];
      if (titleMediaSegment == null) {
        titleMediaSegment = MediaSegment.from(lesson.titleStart, lesson.titleEnd);
        mediaDocPathToTitleMediaSegment[ret.mediaDocPath] = titleMediaSegment;
      }
      if (titleMediaSegment.start == 0 && titleMediaSegment.start == titleMediaSegment.end) {
        ret.titleMediaSegment = null;
      } else {
        ret.titleMediaSegment = titleMediaSegment;
      }

      var qMediaSegments = mediaDocPathToQuestionMediaSegments[ret.mediaDocPath];
      if (qMediaSegments == null) {
        qMediaSegments = [];
        var ok = true;
        for (var s in lesson.segment) {
          var start = s.qStart;
          var end = s.qEnd;
          if (start == '' || end == '') {
            ok = false;
            break;
          }
          qMediaSegments.add(MediaSegment.from(start, end));
        }
        if (!ok) {
          qMediaSegments = [];
        }
        mediaDocPathToQuestionMediaSegments[ret.mediaDocPath] = qMediaSegments;
      }
      ret.qMediaSegments = qMediaSegments;

      var aMediaSegments = mediaDocPathToAnswerMediaSegments[ret.mediaDocPath];
      if (aMediaSegments == null) {
        aMediaSegments = [];
        var ok = true;
        for (var s in lesson.segment) {
          var start = s.aStart;
          var end = s.aEnd;
          if (start == '' || end == '') {
            ok = false;
            break;
          }
          aMediaSegments.add(MediaSegment.from(start, end));
        }
        if (!ok) {
          aMediaSegments = [];
        }
        mediaDocPathToAnswerMediaSegments[ret.mediaDocPath] = aMediaSegments;
      }
      ret.aMediaSegments = aMediaSegments;
    }

    scheduleKeyToLearnSegment[segmentKeyId] = ret;
    return ret;
  }

  static Future<RepeatDoc?> getAndCacheQa(SegmentContent ret, {RxString? err}) async {
    var qa = indexDocPathToQa[ret.indexDocPath];
    if (qa == null) {
      qa = await RepeatDoc.fromPath(ret.indexDocPath, Uri.parse(ret.indexDocUrl));
      if (qa == null) {
        if (err != null) {
          err.value = I18nKey.labelDocNotBeDownloaded.trArgs([ret.indexDocUrl]);
        }
        return null;
      }
      indexDocPathToQa[ret.indexDocPath] = qa;
    }
    return qa;
  }
}
