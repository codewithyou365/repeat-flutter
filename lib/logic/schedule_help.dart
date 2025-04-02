import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/segment_help.dart';

class ScheduleHelp {
  static Future<bool> addContentToScheduleByContentSerial(int contentSerial) async {
    return await innerAddContentToSchedule(0, contentSerial, null, null);
  }

  static Future<bool> addContentToSchedule(int contentId, int indexJsonDocId, String url) async {
    return await innerAddContentToSchedule(contentId, 0, indexJsonDocId, url);
  }

  static Future<bool> innerAddContentToSchedule(int contentId, int contentSerial, int? indexJsonDocId, String? url) async {
    var v = await Db().db.scheduleDao.importSegment(contentId, contentSerial, indexJsonDocId, url);
    var ir = ImportResult.values[v];
    bool ret = ir != ImportResult.error;
    if (ret) {
      await SegmentHelp.tryGen(force: true);
    }
    return ret;
  }
}
