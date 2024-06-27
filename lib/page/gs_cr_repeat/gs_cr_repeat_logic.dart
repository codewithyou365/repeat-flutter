import 'dart:async';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/logic/model/segment_today_prg_with_key.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';

import 'gs_cr_repeat_state.dart';

class GsCrRepeatLogic extends GetxController {
  static const String id = "MainRepeatLogic";
  final GsCrRepeatState state = GsCrRepeatState();
  List<SegmentTodayPrgWithKey> todayProgresses = [];
  Ticker ticker = Ticker(1000);

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
    state.c = SegmentTodayPrg.refineWithFinish(all, false);
    if (state.c.isNotEmpty) {
      todayProgresses = all;
    }
    if (state.c.isEmpty) {
      Get.back();
      return;
    }
    state.total = todayProgresses.length;
    state.progress = state.total - state.c.length;
    state.step = getStepForRecallOrTip();
    state.tryNeedPlayQuestion = true;
    state.tryNeedPlayAnswer = false;
    await setCurrentLearnContent();
    update([GsCrRepeatLogic.id]);
  }

  void show() {
    if (ticker.isStuck()) {
      return;
    }
    state.step = RepeatStep.evaluate;
    state.tryNeedPlayQuestion = false;
    state.tryNeedPlayAnswer = true;
    update([GsCrRepeatLogic.id]);
  }

  void tip() {
    state.step = RepeatStep.tip;
    state.tryNeedPlayQuestion = false;
    state.tryNeedPlayAnswer = false;
    update([GsCrRepeatLogic.id]);
  }

  void error({autoNext = false}) async {
    if (ticker.isStuck()) {
      return;
    }
    if (state.c.isEmpty) {
      finish();
      return;
    }
    state.tryNeedPlayQuestion = false;
    state.tryNeedPlayAnswer = true;
    var curr = state.c[0];
    await Db().db.scheduleDao.error(curr);
    state.c.sort(schedulesCurrentSort);
    if (autoNext) {
      next(fromView: false);
    } else {
      state.step = RepeatStep.finish;
      update([GsCrRepeatLogic.id]);
    }
  }

  Future<void> tryToSetNext() async {
    if (state.c.length > 1) {
      var next = state.c[1];
      var content = await SegmentHelp.from(next.segmentKeyId);
      state.nextKey = content!.k;
    }
  }

  // TODO add device volume button
  void know({autoNext = false}) async {
    if (ticker.isStuck()) {
      return;
    }
    if (state.c.isEmpty) {
      finish();
      return;
    }
    state.tryNeedPlayQuestion = false;
    state.tryNeedPlayAnswer = true;
    var curr = state.c[0];
    await Db().db.scheduleDao.right(curr);
    if (curr.progress >= ScheduleDao.maxRepeatTime) {
      state.c.removeAt(0);
    }
    state.c.sort(schedulesCurrentSort);
    state.progress = state.total - state.c.length;
    if (autoNext && state.c.isNotEmpty) {
      next(fromView: false);
    } else {
      state.step = RepeatStep.finish;
      update([GsCrRepeatLogic.id]);
    }
  }

  void next({fromView = true}) async {
    if (fromView && ticker.isStuck()) {
      return;
    }
    if (state.c.isEmpty) {
      finish();
      return;
    }
    state.step = getStepForRecallOrTip();
    state.tryNeedPlayQuestion = true;
    state.tryNeedPlayAnswer = false;
    await setCurrentLearnContent();
    update([GsCrRepeatLogic.id]);
  }

  Future<void> setCurrentLearnContent() async {
    if (state.c.isEmpty) {
      return;
    }
    var curr = state.c[0];
    tryToSetNext();
    var learnSegment = await SegmentHelp.from(curr.segmentKeyId);
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

  RepeatStep getStepForRecallOrTip() {
    var currProcessShowContent = getCurrProcessShowContent();
    var same = false;
    if (currProcessShowContent.length > 2) {
      var size = currProcessShowContent[0].length;
      if (size == currProcessShowContent[1].length) {
        var allSame = true;
        for (int i = 0; i < size; i++) {
          if (currProcessShowContent[0][i] != currProcessShowContent[i][i]) {
            allSame = false;
            break;
          }
        }
        same = allSame;
      }
    }
    if (same) {
      return RepeatStep.tip;
    } else {
      return RepeatStep.recall;
    }
  }

  List<List<ContentType>> getCurrProcessShowContent() {
    List<List<ContentType>> currProcessShowContent;
    var processIndex = state.progress;
    if (processIndex < 0) {
      currProcessShowContent = state.showContent[0];
    } else if (processIndex < state.showContent.length) {
      currProcessShowContent = state.showContent[processIndex];
    } else {
      currProcessShowContent = state.showContent[state.showContent.length - 1];
    }
    return currProcessShowContent;
  }

  finish() {
    state.tryNeedPlayQuestion = false;
    state.tryNeedPlayAnswer = false;
    Nav.gsCrRepeatFinish.push();
  }
}
