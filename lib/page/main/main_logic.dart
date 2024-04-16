import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
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
    state.schedules.clear();
    state.schedules.addAll(await Db().db.scheduleDao.findSchedule(30, now));
    state.totalCount.value = state.schedules.length;
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
