import 'package:repeat_flutter/common/date.dart';
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
  static Future<bool> addContentToScheduleByContentSerial(int contentSerial) async {
    return await Db().db.scheduleDao.importSegment(contentSerial: contentSerial);
  }

  static Future<bool> addContentToSchedule(int contentId) async {
    return await Db().db.scheduleDao.importSegment(contentId: contentId);
  }
}
