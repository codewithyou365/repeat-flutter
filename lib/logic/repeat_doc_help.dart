import 'package:get/get.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
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

  static double getVideoMaskRatio(int contentSerial, int lessonIndex, String mediaExtension) {
    if (mediaExtension == "") {
      return 20;
    }
    var mediaDocPath = DocPath.getRelativeMediaPath(contentSerial, lessonIndex, mediaExtension);
    var ret = mediaDocPathToVideoMaskRatio[mediaDocPath];
    if (ret != null && ret > 0) {
      return ret;
    }
    return 20;
  }

  static void setVideoMaskRatio(int contentSerial, int lessonIndex, String mediaExtension, double ratio) {
    var mediaDocPath = DocPath.getRelativeMediaPath(contentSerial, lessonIndex, mediaExtension);
    mediaDocPathToVideoMaskRatio[mediaDocPath] = ratio;
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
      if (err != null) {
        var name = await Db().db.scheduleDao.getContentName(segmentKeyId);
        err.value = I18nKey.labelDocCantBeFound.trArgs([name ?? '']);
      }
      return null;
    }
    var ret = SegmentContent.from(retInDb);
    ret.k = getKey(ret.contentName, ret.lessonIndex, ret.segmentIndex);
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
        ret.aStart = segment.aStart;
        ret.aEnd = segment.aEnd;
        var words = segment.w;
        if (words == "") {
          words = segment.a;
        }
        ret.word = words.replaceAll(PlaceholderToken.using, PlaceholderToken.replace);
      } else {
        ret.miss = true;
      }
    }

    // full mediaSegments
    if (lesson.mediaExtension != "") {
      var mediaDocPath = DocPath.getRelativeMediaPath(ret.contentSerial, ret.lessonIndex, lesson.mediaExtension);
      ret.mediaDocPath = await DocPath.getContentPath();
      ret.mediaDocPath = ret.mediaDocPath.joinPath(mediaDocPath);
      ret.mediaHash = lesson.hash;
      ret.mediaExtension = lesson.mediaExtension;
      // for mask ratio
      var ratio = mediaDocPathToVideoMaskRatio[mediaDocPath];
      if (ratio == null && lesson.videoMaskRatio != "") {
        double va = double.parse(lesson.videoMaskRatio);
        mediaDocPathToVideoMaskRatio[mediaDocPath] = va;
      } else {
        mediaDocPathToVideoMaskRatio[mediaDocPath] = 20;
      }

      var titleMediaSegment = mediaDocPathToTitleMediaSegment[mediaDocPath];
      if (titleMediaSegment == null) {
        titleMediaSegment = MediaSegment.from(lesson.titleStart, lesson.titleEnd);
        mediaDocPathToTitleMediaSegment[mediaDocPath] = titleMediaSegment;
      }
      if (titleMediaSegment.start == 0 && titleMediaSegment.start == titleMediaSegment.end) {
        ret.titleMediaSegment = null;
      } else {
        ret.titleMediaSegment = titleMediaSegment;
      }

      var qMediaSegments = mediaDocPathToQuestionMediaSegments[mediaDocPath];
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
        mediaDocPathToQuestionMediaSegments[mediaDocPath] = qMediaSegments;
      }
      ret.qMediaSegments = qMediaSegments;

      var aMediaSegments = mediaDocPathToAnswerMediaSegments[mediaDocPath];
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
        mediaDocPathToAnswerMediaSegments[mediaDocPath] = aMediaSegments;
      }
      ret.aMediaSegments = aMediaSegments;
    }

    scheduleKeyToLearnSegment[segmentKeyId] = ret;
    return ret;
  }

  static Future<RepeatDoc?> getAndCacheQa(SegmentContent ret, {RxString? err}) async {
    var path = DocPath.getRelativeIndexPath(ret.contentSerial);
    var qa = indexDocPathToQa[path];
    if (qa == null) {
      qa = await RepeatDoc.fromPath(path);
      if (qa == null) {
        if (err != null) {
          err.value = I18nKey.labelDocNotBeDownloaded.trArgs([ret.contentName]);
        }
        return null;
      }
      indexDocPathToQa[path] = qa;
    }
    return qa;
  }

  static String getKey(String contentName, int lessonIndex, int segmentIndex) {
    return '$contentName|${lessonIndex + 1}|${segmentIndex + 1}';
  }
}
