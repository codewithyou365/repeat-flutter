import 'dart:async';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/logic/model/segment_today_prg_with_key.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'gs_cr_state.dart';

class GsCrLogic extends GetxController {
  final GsCrState state = GsCrState();
  List<SegmentTodayPrgWithKey> todayProgresses = [];
  Timer? timer;

  @override
  void onInit() {
    super.onInit();
    SegmentHelp.clear();
    init();
  }

  void init() async {
    var now = DateTime.now();
    todayProgresses = await Db().db.scheduleDao.initToday();

    var todayLearnCreateDate = await Db().db.scheduleDao.valueKv(Classroom.curr, CrK.todayLearnCreateDate) ?? 0;
    var next = Db().db.scheduleDao.getNext(now, ScheduleDao.intervalSeconds);
    if (todayLearnCreateDate != 0 && next.value - todayLearnCreateDate > 0 && todayLearnCreateDate == Date.from(now).value) {
      state.learnDeadline = next.toDateTime().millisecondsSinceEpoch;
    }
    resetLearnDeadline();

    state.learnTotalCount.value = SegmentTodayPrg.getUnfinishedCount(todayProgresses);

    startTimer();
  }

  tryLearn() {
    if (state.learnTotalCount.value == 0) {
      Snackbar.show(I18nKey.labelNoLearningContent.tr);
      return;
    }
    Nav.gsCrRepeat.push();
  }

  tryReview() {
    if (state.reviewTotalCount.value == 0) {
      Snackbar.show(I18nKey.labelNoLearningContent.tr);
      return;
    }
    Nav.gsCrRepeat.push();
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
