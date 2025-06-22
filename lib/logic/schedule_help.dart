import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/base/constant.dart';

class ScheduleHelp {
  static Future<bool> addBookToSchedule(int bookId, String url) async {
    var v = await Db().db.scheduleDao.importVerse(bookId, url);
    var ir = ImportResult.values[v];
    bool ret = ir != ImportResult.error;
    return ret;
  }
}
