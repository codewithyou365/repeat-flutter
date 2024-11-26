import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
import 'package:repeat_flutter/db/entity/segment.dart' as entity;
import 'package:repeat_flutter/db/entity/segment_key.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class ScheduleHelp {
  static Future<bool> addToScheduleByUrl(String url) async {
    ContentIndex? ci = await Db().db.contentIndexDao.one(Classroom.curr, url);
    if (ci == null) {
      return false;
    }
    var ret = await addToSchedule(url, ci.sort);
    return ret;
  }

  static Future<bool> addToSchedule(String url, int contentIndexSort) async {
    var doc = await downloadDocInfo(url);
    if (doc == null) {
      return false;
    }
    List<SegmentKey> segmentKeys = [];
    List<entity.Segment> segments = [];
    List<SegmentOverallPrg> segmentOverallPrgs = [];
    var kv = await RepeatDoc.fromPath(doc.path, Uri.parse(url));
    if (kv == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return false;
    }
    if (kv.lesson.length >= 100000) {
      Snackbar.show(I18nKey.labelTooMuchData.tr);
      return false;
    }
    for (var d in kv.lesson) {
      if (d.segment.length >= 100000) {
        Snackbar.show(I18nKey.labelTooMuchData.tr);
        return false;
      }
    }
    var now = DateTime.now();
    for (var lessonIndex = 0; lessonIndex < kv.lesson.length; lessonIndex++) {
      var lesson = kv.lesson[lessonIndex];
      var mediaDocId = 0;
      if (lesson.url != "") {
        if (!lesson.url.startsWith("http")) {
          lesson.url = kv.rootUrl.joinPath(lesson.url);
        }
        var docId = await Db().db.docDao.getId(lesson.url);
        mediaDocId = docId!;
      }
      for (var segmentIndex = 0; segmentIndex < lesson.segment.length; segmentIndex++) {
        var segment = lesson.segment[segmentIndex];
        var key = "${kv.rootPath}|${lesson.key}|${segment.key}";
        //4611686118427387904-(99999*10000000000+99999*100000+99999)
        segmentKeys.add(SegmentKey(
          Classroom.curr,
          key,
        ));
        segments.add(entity.Segment(
          0,
          doc.id!,
          mediaDocId,
          lessonIndex,
          segmentIndex,
          contentIndexSort * 10000000000 + lessonIndex * 100000 + segmentIndex,
        ));
        segmentOverallPrgs.add(SegmentOverallPrg(0, Date.from(now), 0));
      }
    }
    await Db().db.scheduleDao.importSegment(segmentKeys, segments, segmentOverallPrgs);
    return true;
  }
}
