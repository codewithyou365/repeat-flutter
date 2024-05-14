import 'dart:async';

import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/segment_current_prg.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';

import 'gs_cr_repeat_state.dart';

class GsCrRepeatLogic extends GetxController {
  static const String id = "MainRepeatLogic";
  final GsCrRepeatState state = GsCrRepeatState();

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
    if (Get.arguments == "review") {
      state.forReview = {};
      state.c = await Db().db.scheduleDao.initToday(state.forReview!);
    } else {
      state.c = await Db().db.scheduleDao.initToday(null);
    }
    var total = await Db().db.scheduleDao.totalSegmentCurrentPrg(Classroom.curr, Get.arguments != "review");
    state.total = total!;
    state.progress = state.total - state.c.length;
    state.step = RepeatStep.recall;
    state.mode = RepeatMode.byQuestion;
    await setCurrentLearnContent();
    update([GsCrRepeatLogic.id]);
  }

  void show() {
    state.step = RepeatStep.evaluate;
    update([GsCrRepeatLogic.id]);
  }

  void error({autoNext = false}) async {
    if (state.c.isEmpty) {
      finish();
      return;
    }
    var curr = state.c[0];
    await Db().db.scheduleDao.error(curr, state.forReview?[curr.k] ?? []);
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
    await Db().db.scheduleDao.right(curr, state.forReview?[curr.k] ?? []);
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

  int schedulesCurrentSort(SegmentCurrentPrg a, SegmentCurrentPrg b) {
    if (a.viewTime != b.viewTime) {
      return a.viewTime.compareTo(b.viewTime);
    } else {
      return a.sort.compareTo(b.sort);
    }
  }

  finish() {
    if (state.forReview != null) {
      Nav.gsCrRepeatFinish.push(arguments: "review");
    } else {
      Nav.gsCrRepeatFinish.push();
    }
  }
}
