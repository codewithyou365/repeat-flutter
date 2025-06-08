import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/base/constant.dart';

class ScheduleHelp {
  static Future<bool> addContentToScheduleBybookSerial(int bookSerial) async {
    return await innerAddContentToSchedule(0, bookSerial, null, null);
  }

  static Future<bool> addContentToSchedule(int contentId, int indexJsonDocId, String url) async {
    return await innerAddContentToSchedule(contentId, 0, indexJsonDocId, url);
  }

  static Future<bool> innerAddContentToSchedule(int contentId, int bookSerial, int? indexJsonDocId, String? url) async {
    var v = await Db().db.scheduleDao.importVerse(contentId, bookSerial, indexJsonDocId, url);
    var ir = ImportResult.values[v];
    bool ret = ir != ImportResult.error;
    return ret;
  }
}
