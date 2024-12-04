import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content.dart';
import 'package:repeat_flutter/db/entity/segment.dart' as entity;
import 'package:repeat_flutter/db/entity/segment_key.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class ScheduleHelp {
  static Future<bool> addMaterialToScheduleByContentSerial(int contentSerial) async {
    Content? ci = await Db().db.materialDao.getContentBySerial(Classroom.curr, contentSerial);
    if (ci == null) {
      return false;
    }
    var ret = await addContentToSchedule(ci);
    return ret;
  }

  static Future<bool> addContentToSchedule(Content material) async {
    var doc = await Db().db.docDao.getById(material.docId);
    if (doc == null) {
      return false;
    }
    List<SegmentKey> segmentKeys = [];
    List<entity.Segment> segments = [];
    List<SegmentOverallPrg> segmentOverallPrgs = [];
    var kv = await RepeatDoc.fromPath(DocPath.getRelativeIndexPath(material.serial));
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
      for (var segmentIndex = 0; segmentIndex < lesson.segment.length; segmentIndex++) {
        segmentKeys.add(SegmentKey(
          material.classroomId,
          material.serial,
          lessonIndex,
          segmentIndex,
        ));
        segments.add(entity.Segment(
          0,
          material.classroomId,
          material.serial,
          lessonIndex,
          segmentIndex,
          //4611686118427387904-(99999*10000000000+99999*100000+99999)
          material.sort * 10000000000 + lessonIndex * 100000 + segmentIndex,
        ));
        segmentOverallPrgs.add(SegmentOverallPrg(0, material.classroomId, material.serial, Date.from(now), 0));
      }
    }
    await Db().db.scheduleDao.importSegment(segmentKeys, segments, segmentOverallPrgs);
    return true;
  }
}
