import 'dart:async';

import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';

import 'gs_cr_repeat_state.dart';

class GsCrRepeatLogic extends GetxController {
  static const String id = "MainRepeatLogic";
  final GsCrRepeatState state = GsCrRepeatState();
  List<SegmentTodayPrg> todayProgresses = [];
  TodayPrgType todayPrgType = TodayPrgType.learn;

  @override
  Future<void> onInit() async {
    super.onInit();
    await init();
  }

  @override
  void onClose() {
    super.onClose();
    Get.find<GsCrLogic>().init();
  }

  init() async {
    var all = Get.find<GsCrLogic>().todayProgresses;
    if (Get.arguments == "review") {
      todayPrgType = TodayPrgType.review;
    } else {
      todayPrgType = TodayPrgType.learn;
    }
    var levelAndGroupNumber = SegmentTodayPrg.getLevelAndGroupNumber(all, todayPrgType);
    for (int lg in levelAndGroupNumber) {
      state.c = SegmentTodayPrg.refine(all, todayPrgType, lg, false);
      if (state.c.isNotEmpty) {
        todayProgresses = SegmentTodayPrg.refine(all, todayPrgType, lg, true);
        break;
      }
    }
    if (state.c.isEmpty) {
      Get.back();
      return;
    }
    state.total = todayProgresses.length;
    state.progress = state.total - state.c.length;
    state.step = RepeatStep.recall;
    await setCurrentLearnContent();
    update([GsCrRepeatLogic.id]);
  }

  void show() {
    state.step = RepeatStep.evaluate;
    update([GsCrRepeatLogic.id]);
  }

  void tip() {
    state.step = RepeatStep.tip;
    update([GsCrRepeatLogic.id]);
  }

  void error({autoNext = false}) async {
    if (state.c.isEmpty) {
      finish();
      return;
    }
    var curr = state.c[0];
    await Db().db.scheduleDao.error(curr);
    state.c.sort(schedulesCurrentSort);
    if (autoNext) {
      next();
    } else {
      state.step = RepeatStep.finish;
      update([GsCrRepeatLogic.id]);
    }
  }

  // TODO add device volume button
  void know({autoNext = false}) async {
    if (state.c.isEmpty) {
      finish();
      return;
    }
    var curr = state.c[0];
    await Db().db.scheduleDao.right(curr);
    if (curr.progress >= ScheduleDao.maxRepeatTime) {
      state.c.removeAt(0);
    }
    state.c.sort(schedulesCurrentSort);
    state.progress = state.total - state.c.length;
    if (autoNext && state.c.isNotEmpty) {
      next();
    } else {
      state.step = RepeatStep.finish;
      update([GsCrRepeatLogic.id]);
    }
  }

  void next() async {
    if (state.c.isEmpty) {
      finish();
      return;
    }
    state.step = RepeatStep.recall;
    await setCurrentLearnContent();
    update([GsCrRepeatLogic.id]);
  }

  Future<void> setCurrentLearnContent() async {
    if (state.c.isEmpty) {
      return;
    }
    var curr = state.c[0];
    var learnSegment = await SegmentHelp.from(curr.k);
    if (learnSegment == null) {
      return;
    }
    state.segment = learnSegment;
  }

  int schedulesCurrentSort(SegmentTodayPrg a, SegmentTodayPrg b) {
    if (a.viewTime != b.viewTime) {
      return a.viewTime.compareTo(b.viewTime);
    } else {
      return a.sort.compareTo(b.sort);
    }
  }

  finish() {
    if (todayPrgType == TodayPrgType.review) {
      Nav.gsCrRepeatFinish.push(arguments: "review");
    } else {
      Nav.gsCrRepeatFinish.push();
    }
  }
}
