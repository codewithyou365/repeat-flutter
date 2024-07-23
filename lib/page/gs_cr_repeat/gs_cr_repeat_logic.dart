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
    state.step = RepeatStep.recall;
    state.tryNeedPlayQuestion = true;
    state.tryNeedPlayAnswer = false;
    state.fakeKnow = 0;
    await setCurrentLearnContentAndUpdateView();
  }

  void show() {
    if (ticker.isStuck()) {
      return;
    }
    state.step = RepeatStep.evaluate;
    state.tryNeedPlayQuestion = false;
    state.tryNeedPlayAnswer = true;
    state.fakeKnow = 1;
    update([GsCrRepeatLogic.id]);
  }

  void tip() {
    state.openTip = true;
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
    state.fakeKnow = 0;
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
    state.fakeKnow = 0;
    var curr = state.c[0];
    await Db().db.scheduleDao.right(curr);
    if (curr.progress >= ScheduleDao.scheduleConfig.maxRepeatTime) {
      state.c.removeAt(0);
    }
    state.c.sort(schedulesCurrentSort);
    state.progress = state.total - state.c.length;
    if (autoNext && state.c.isNotEmpty) {
      state.tryNeedPlayQuestion = false;
      state.tryNeedPlayAnswer = true;
      next(fromView: false);
    } else {
      state.tryNeedPlayQuestion = false;
      state.tryNeedPlayAnswer = false;
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
    state.step = RepeatStep.recall;
    state.tryNeedPlayQuestion = true;
    state.tryNeedPlayAnswer = false;
    state.fakeKnow = 0;
    await setCurrentLearnContentAndUpdateView();
  }

  Future<bool?> setCurrentLearnContentAndUpdateView({int? pnOffset, needDiff = false}) async {
    if (state.c.isEmpty) {
      return null;
    }
    var curr = state.c[0];
    tryToSetNext();
    pnOffset ??= 0;
    state.openTip = false;
    var oldSegmentKeyId = state.segment.segmentKeyId;
    var learnSegment = await SegmentHelp.from(curr.segmentKeyId, offset: pnOffset);
    if (learnSegment == null) {
      return null;
    }
    if (learnSegment.segmentKeyId == oldSegmentKeyId && needDiff) {
      return false;
    }
    state.segment = learnSegment;
    update([GsCrRepeatLogic.id]);
    return true;
  }

  Future<void> resetPnOffset() async {
    setCurrentLearnContentAndUpdateView(pnOffset: 0);
    state.pnOffset = 0;
  }

  Future<void> plusPnOffset() async {
    var diff = await setCurrentLearnContentAndUpdateView(pnOffset: state.pnOffset + 1, needDiff: true);
    if (diff ?? false) {
      ++state.pnOffset;
    }
  }

  Future<void> minusPnOffset() async {
    var diff = await setCurrentLearnContentAndUpdateView(pnOffset: state.pnOffset - 1, needDiff: true);
    if (diff ?? false) {
      --state.pnOffset;
    }
  }

  int schedulesCurrentSort(SegmentTodayPrg a, SegmentTodayPrg b) {
    if (a.viewTime != b.viewTime) {
      return a.viewTime.compareTo(b.viewTime);
    } else {
      return a.sort.compareTo(b.sort);
    }
  }

  List<List<ContentTypeWithTip>> getCurrProcessShowContent() {
    List<List<ContentTypeWithTip>> currProcessShowContent;
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
    state.fakeKnow = 0;
    Nav.gsCrRepeatFinish.push();
  }
}
