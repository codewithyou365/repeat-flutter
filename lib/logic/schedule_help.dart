import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/base/constant.dart';

class ScheduleHelp {
  static Future<bool> addContentToScheduleByContentSerial(int contentSerial) async {
    var v = await Db().db.scheduleDao.importSegment(0, contentSerial, null, null);
    var ir = ImportResult.values[v];
    return ir != ImportResult.error;
  }

  static Future<bool> addContentToSchedule(int contentId, int indexJsonDocId, String url) async {
    var v = await Db().db.scheduleDao.importSegment(contentId, 0, indexJsonDocId, url);
    var ir = ImportResult.values[v];
    return ir != ImportResult.error;
  }
}
