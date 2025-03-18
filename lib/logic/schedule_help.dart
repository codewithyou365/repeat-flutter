import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/base/constant.dart';

class ScheduleHelp {
  static Future<bool> addContentToScheduleByContentSerial(int contentSerial) async {
    var v = await Db().db.scheduleDao.importSegment(0, contentSerial);
    var ir = ImportResult.values[v];
    return ir != ImportResult.error;
  }

  static Future<ImportResult> addContentToSchedule(int contentId) async {
    var r = await Db().db.scheduleDao.importSegment(contentId, 0);
    return ImportResult.values[r];
  }
}
