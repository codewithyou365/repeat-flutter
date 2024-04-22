import 'dart:ffi';
import 'dart:math';

import 'package:floor/floor.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/segment_review.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/nav.dart';

import '../../logic/model/segment_review_content.dart';
import 'main_state.dart';

class MainLogic extends GetxController {
  final MainState state = MainState();

  @override
  void onInit() {
    super.onInit();
    init();
  }

  void init() async {
    var dao = Db().db.scheduleDao;
    var now = DateTime.now();
    var learned = await Db().db.scheduleDao.findLearnedCount(Date.from(now));
    var unlearned = await Db().db.scheduleDao.findSegmentOverallPrgCount(ScheduleDao.learnCountPerDay, now);

    state.learnTotalCount.value = min(ScheduleDao.learnCountPerDay - learned!, unlearned!);

    for (int i = 0; i < ScheduleDao.review.length; i++) {
      var minCreateDate = await dao.findReviewedMinCreateDate(i, Date.from(now.subtract(Duration(seconds: ScheduleDao.review[i]))));
      if (minCreateDate == null) {
        continue;
      }
      List<SegmentReview> reviewed = await dao.findReviewed(Date.from(now));
      if (ScheduleDao.reviewMaxCount - reviewed.length <= 0) {
        continue;
      }
      List<SegmentReviewContentInDb> tss = await dao.scheduleReviewToday(i, minCreateDate, ScheduleDao.reviewMaxCount - reviewed.length);

      state.reviewLevelCount.value = i;
      state.reviewTotalCount.value = tss.length;
      break;
    }
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
}
