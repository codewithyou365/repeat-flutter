import 'dart:math';

import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/date_help.dart';
import 'package:repeat_flutter/nav.dart';

import 'main_state.dart';

class MainLogic extends GetxController {
  final MainState state = MainState();

  @override
  void onInit() {
    super.onInit();
    init();
  }

  void init() async {
    var now = DateTime.now();
    var learned = await Db().db.scheduleDao.findLearnedCount(DateHelp.from(now));
    var unlearned = await Db().db.scheduleDao.findSegmentOverallPrgCount(ScheduleDao.learnCountPerDay, now);

    state.totalCount.value = min(ScheduleDao.learnCountPerDay - learned!, unlearned!);
  }

  tryMainRepeat() {
    if (state.totalCount.value == 0) {
      Get.snackbar(
        I18nKey.labelTips.tr,
        I18nKey.labelNoLearningContent.tr,
      );
      return;
    }
    Nav.mainRepeat.push();
  }
}
