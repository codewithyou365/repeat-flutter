import 'dart:async';

import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/segment_current_prg.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/main/main_logic.dart';

import 'main_repeat_state.dart';

class MainRepeatLogic extends GetxController {
  static const String id = "MainRepeatLogic";
  final MainRepeatState state = MainRepeatState();

  @override
  Future<void> onInit() async {
    super.onInit();
    await init();
  }

  @override
  void onClose() {
    super.onClose();
    Get.find<MainLogic>().init();
  }

  init() async {
    if (Get.arguments == "review") {
      state.forReview = {};
      state.c = await Db().db.scheduleDao.initToday(state.forReview!);
    } else {
      state.c = await Db().db.scheduleDao.initToday(null);
    }
    var total = await Db().db.scheduleDao.totalSegmentCurrentPrg(Get.arguments != "review");
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

  void error({autoNext = false}) async {
    if (state.c.isEmpty) {
      finish();
      return;
    }
    var curr = state.c[0];
    await Db().db.scheduleDao.error(curr, state.forReview?[curr.k] ?? []);
    state.c.sort(schedulesCurrentSort);
    state.step = MainRepeatStep.finish;
    if (autoNext) {
      next();
    } else {
      update([MainRepeatLogic.id]);
    }
  }

  void know() async {
    if (state.c.isEmpty) {
      finish();
      return;
    }
    var curr = state.c[0];
    await Db().db.scheduleDao.right(curr, state.forReview?[curr.k] ?? []);
    if (curr.progress >= ScheduleDao.maxRepeatTime) {
      state.c.removeAt(0);
    }
    state.c.sort(schedulesCurrentSort);
    state.progress = state.total - state.c.length;
    state.step = MainRepeatStep.finish;
    update([MainRepeatLogic.id]);
  }

  void next() async {
    if (state.c.isEmpty) {
      finish();
      return;
    }
    state.step = MainRepeatStep.recall;
    await setCurrentLearnContent();
    update([MainRepeatLogic.id]);
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

  int schedulesCurrentSort(SegmentCurrentPrg a, SegmentCurrentPrg b) {
    if (a.viewTime != b.viewTime) {
      return a.viewTime.compareTo(b.viewTime);
    } else {
      return a.sort.compareTo(b.sort);
    }
  }

  finish() {
    if (state.forReview != null) {
      Nav.mainRepeatFinish.push(arguments: "review");
    } else {
      Nav.mainRepeatFinish.push();
    }
  }
}
