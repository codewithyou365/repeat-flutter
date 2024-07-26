import 'dart:async';

import 'dart:convert' as convert;
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
  static const String id = "GsCrLogic";
  final GsCrState state = GsCrState();
  List<SegmentTodayPrgWithKey> currProgresses = [];
  Timer? timer;

  @override
  void onInit() {
    super.onInit();
    SegmentHelp.clear();
    init();
  }

  Future<void> init() async {
    var now = DateTime.now();
    List<SegmentTodayPrgWithKey> allProgresses = await Db().db.scheduleDao.initToday();
    currProgresses = allProgresses;
    state.segments = [];

    var configInUseJsonStr = await Db().db.scheduleDao.stringKv(Classroom.curr, CrK.todayLearnScheduleConfigInUse);
    ScheduleConfig? scheduleConfig;
    if (configInUseJsonStr != null) {
      try {
        Map<String, dynamic> configJson = convert.jsonDecode(configInUseJsonStr);
        scheduleConfig = ScheduleConfig.fromJson(configJson);
      } catch (_) {}
    }
    List<SegmentTodayPrgWithKeyInView> learn = [];
    List<SegmentTodayPrgWithKeyInView> review = [];
    Map<int, SegmentTodayPrgWithKeyInView> temp = {};
    for (var item in allProgresses) {
      var prgType = SegmentTodayPrg.getPrgType(item.type);
      var index = SegmentTodayPrg.getIndex(item.type);
      var prgTypeAndIndex = SegmentTodayPrg.getPrgTypeAndIndex(item.type);

      SegmentTodayPrgWithKeyInView view;
      if (temp.containsKey(prgTypeAndIndex)) {
        view = temp[prgTypeAndIndex]!;
      } else {
        view = SegmentTodayPrgWithKeyInView(
          index,
          prgTypeAndIndex,
          "",
          prgType.name.toString().toUpperCase(),
          scheduleConfig?.elConfigs.elementAt(index).tr() ?? index.toString(),
          [],
        );
        temp[prgTypeAndIndex] = view;
      }
      view.segments.add(item);
      view.name = "片段共计${view.segments.length}";
    }
    if (scheduleConfig != null) {
      for (var index = 0; index < scheduleConfig.elConfigs.length; index++) {
        var prgTypeAndIndex = SegmentTodayPrg.toPrgTypeAndIndex(0, index);
        if (temp.containsKey(prgTypeAndIndex)) {
          learn.add(temp[prgTypeAndIndex]!);
        } else {
          learn.add(SegmentTodayPrgWithKeyInView(
            index,
            prgTypeAndIndex,
            "片段共计0",
            TodayPrgType.learn.name.toString().toUpperCase(),
            scheduleConfig.elConfigs.elementAt(index).tr(),
            [],
          ));
        }
      }
      for (var index = 0; index < scheduleConfig.relConfigs.length; index++) {
        var prgTypeAndIndex = SegmentTodayPrg.toPrgTypeAndIndex(1, index);
        if (temp.containsKey(prgTypeAndIndex)) {
          review.add(temp[prgTypeAndIndex]!);
        } else {
          review.add(SegmentTodayPrgWithKeyInView(
            index,
            prgTypeAndIndex,
            "片段共计0",
            TodayPrgType.review.name.toString().toUpperCase(),
            scheduleConfig.relConfigs.elementAt(index).tr(),
            [],
          ));
        }
      }
    }
    state.segments.addAll(learn);
    state.segments.addAll(review);

    var todayLearnCreateDate = await Db().db.scheduleDao.intKv(Classroom.curr, CrK.todayLearnCreateDate) ?? 0;
    var next = Db().db.scheduleDao.getNext(now, ScheduleDao.scheduleConfig.intervalSeconds);
    if (todayLearnCreateDate != 0 && next.value - todayLearnCreateDate > 0 && todayLearnCreateDate == Date.from(now).value) {
      state.learnDeadline = next.toDateTime().millisecondsSinceEpoch;
    }
    resetLearnDeadline();

    state.learnTotalCount.value = SegmentTodayPrg.getUnfinishedCount(currProgresses);

    startTimer();
    update([GsCrLogic.id]);
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
