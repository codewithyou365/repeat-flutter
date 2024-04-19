import 'dart:async';

import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/nav.dart';

import 'main_repeat_state.dart';

class MainRepeatLogic extends GetxController {
  static const String id = "MainRepeatLogic";
  final MainRepeatState state = MainRepeatState();

  @override
  Future<void> onInit() async {
    super.onInit();
    await init();
  }

  init() async {
    state.c = await Db().db.scheduleDao.initToday();
    var total = await Db().db.scheduleDao.totalSegmentTodayPrg();
    state.total = total!;
    state.progress = state.total - state.c.length;
    state.step = MainRepeatStep.recall;
    state.mode = MainRepeatMode.byQuestion;
    await setCurrentLearnContent();
    update([MainRepeatLogic.id]);
  }

  void show() {
    state.step = MainRepeatStep.evaluate;
    update([MainRepeatLogic.id]);
  }

  void error() async {
    if (state.c.isEmpty) {
      finish();
      return;
    }
    var curr = state.c[0];
    await Db().db.scheduleDao.error(curr);
    state.c.sort(schedulesCurrentSort);
    state.step = MainRepeatStep.finish;
    update([MainRepeatLogic.id]);
  }

  void know() async {
    if (state.c.isEmpty) {
      finish();
      return;
    }
    var curr = state.c[0];
    await Db().db.scheduleDao.right(curr);
    if (curr.progress >= ScheduleDao.maxRepeatTime) {
      state.c.removeAt(0);
    }
    if (state.c.isEmpty) {
      finish();
      return;
    }
    state.c.sort(schedulesCurrentSort);
    state.progress = state.total - state.c.length;
    state.step = MainRepeatStep.finish;
    update([MainRepeatLogic.id]);
  }

  void next() async {
    state.step = MainRepeatStep.recall;
    await setCurrentLearnContent();
    update([MainRepeatLogic.id]);
  }

  Future<void> setCurrentLearnContent() async {
    if (state.c.isEmpty) {
      return;
    }
    var curr = state.c[0];
    var learnSegment = await SegmentHelp.from(curr.key);
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
    Nav.mainRepeatFinish.push();
  }
}
