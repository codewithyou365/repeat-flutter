import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/duration.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/nav.dart';

import 'main_state.dart';

class MainLogic extends GetxController {
  final MainState state = MainState();
  Timer? timer;

  @override
  void onInit() {
    super.onInit();
    init();
  }

  void init() async {
    var now = DateTime.now();
    await Db().db.scheduleDao.tryClear();
    var todayLearnCreateTime = await Db().db.scheduleDao.value(K.todayLearnCreateTime) ?? 0;
    state.learnDeadline = todayLearnCreateTime + ScheduleDao.intervalSeconds * 1000 - 300000;
    resetLearnDeadline();

    var learned = await Db().db.scheduleDao.findLearnedCount(Date.from(now));
    var unlearned = await Db().db.scheduleDao.findSegmentOverallPrgCount(ScheduleDao.learnCountPerDay, now);
    state.learnTotalCount.value = min(ScheduleDao.learnCountPerDay - learned!, unlearned!);

    var review = await Db().db.scheduleDao.forReviewInsert(now, {}, [false]);
    if (review.isEmpty) {
      state.reviewLevelCount.value = 0;
      state.reviewTotalCount.value = 0;
    } else {
      state.reviewLevelCount.value = review.first.reviewCount;
      state.reviewTotalCount.value = review.length;
    }

    startTimer();
  }

  tryLearn() {
    if (state.learnTotalCount.value == 0) {
      Get.snackbar(
        I18nKey.labelTips.tr,
        I18nKey.labelNoLearningContent.tr,
      );
      return;
    }
    Nav.mainRepeat.push();
  }

  tryReview() {
    if (state.reviewTotalCount.value == 0) {
      Get.snackbar(
        I18nKey.labelTips.tr,
        I18nKey.labelNoLearningContent.tr,
      );
      return;
    }
    Nav.mainRepeat.push(arguments: "review");
  }

  resetLearnDeadline() {
    var now = DateTime.now();
    if (now.millisecondsSinceEpoch < state.learnDeadline) {
      state.learnDeadlineTips.value = I18nKey.labelResetLearningContent.trArgs([formatHm(state.learnDeadline - now.millisecondsSinceEpoch)]);
    } else {
      state.learnDeadlineTips.value = "";
    }
  }

  void startTimer() {
    if (timer != null) {
      timer!.cancel();
    }
    const duration = Duration(minutes: 1);
    timer = Timer.periodic(duration, (Timer timer) {
      resetLearnDeadline();
    });
  }
}
