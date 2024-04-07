import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';

import 'main_state.dart';

class MainLogic extends GetxController {
  final MainState state = MainState();

  init() async {
    state.schedules.clear();
    state.schedules.addAll(await Db().db.scheduleDao.findSchedule(30));
    state.totalCount.value = state.schedules.length;
  }
}
