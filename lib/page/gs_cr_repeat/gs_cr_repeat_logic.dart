import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/db/entity/video_attribute.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/constant.dart';
import 'package:repeat_flutter/logic/model/segment_today_prg_with_key.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

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
    var all = Get.find<GsCrLogic>().currProgresses;
    state.justView = false;
    if (Get.arguments == Repeat.justView) {
      state.justView = true;
      state.c = all;
    } else {
      state.c = SegmentTodayPrg.refineWithFinish(all, false);
    }
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
    state.skipControlMedia = true;
    update([GsCrRepeatLogic.id]);
  }

  void tipLongPress() {
    Snackbar.show(I18nKey.labelOnTapError.tr);
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
    if (!state.justView) {
      await Db().db.scheduleDao.error(curr);
    }
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
    if (!state.justView) {
      await Db().db.scheduleDao.right(curr);
    }
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

  void showForJustView() {
    if (ticker.isStuck()) {
      return;
    }
    state.step = RepeatStep.evaluate;
    state.tryNeedPlayQuestion = false;
    state.tryNeedPlayAnswer = true;
    update([GsCrRepeatLogic.id]);
  }

  void nextForJustView() async {
    if (ticker.isStuck()) {
      return;
    }
    state.step = RepeatStep.recall;
    state.tryNeedPlayQuestion = true;
    state.tryNeedPlayAnswer = false;
    state.fakeKnow = 0;
    if (state.justViewIndex < state.c.length - 1) {
      state.justViewIndex++;
    }
    await setCurrentLearnContentAndUpdateView(index: state.justViewIndex);
  }

  void previousForJustView() async {
    if (ticker.isStuck()) {
      return;
    }
    state.step = RepeatStep.recall;
    state.tryNeedPlayQuestion = true;
    state.tryNeedPlayAnswer = false;
    state.fakeKnow = 0;
    if (state.justViewIndex > 0) {
      state.justViewIndex--;
    }
    await setCurrentLearnContentAndUpdateView(index: state.justViewIndex);
  }

  Future<bool?> setCurrentLearnContentAndUpdateView({int index = 0, int? pnOffset}) async {
    if (state.c.isEmpty) {
      return null;
    }
    var curr = state.c[index];
    tryToSetNext();
    bool fromPn = false;
    if (pnOffset != null) {
      fromPn = true;
    }
    pnOffset ??= 0;
    state.openTip = false;
    var oldSegmentKeyId = state.segment.segmentKeyId;
    var learnSegment = await SegmentHelp.from(curr.segmentKeyId, offset: pnOffset);
    if (learnSegment == null) {
      return null;
    }
    if (learnSegment.miss) {
      MsgBox.yesOrNo(
        I18nKey.btnTips.tr,
        I18nKey.labelSegmentRemoved.tr,
        yes: () {
          showOverlay(() async {
            await Db().db.scheduleDao.deleteBySegmentKeyId(curr.segmentKeyId);
            Nav.gsCr.until();
          }, I18nKey.labelExecuting.tr);
        },
      );
      return null;
    }
    if (learnSegment.segmentKeyId == oldSegmentKeyId && fromPn) {
      return false;
    }
    state.segment = learnSegment;
    if (!fromPn) {
      state.currSegment = learnSegment;
    }
    update([GsCrRepeatLogic.id]);
    return true;
  }

  void mediaLoad(List<ContentType> contentTypes) {
    if (state.skipControlMedia) {
      state.skipControlMedia = false;
      return;
    }
    if (contentTypes.contains(ContentType.questionOrPrevAnswerOrTitleMedia) || contentTypes.contains(ContentType.questionOrPrevAnswerOrTitleMediaPncAndWom)) {
      if (state.questionMediaKey.currentState != null) {
        state.questionMediaKey.currentState?.mediaLoad();
      }
    }
    if (contentTypes.contains(ContentType.answerMedia) || contentTypes.contains(ContentType.answerMediaPnc)) {
      if (state.answerMediaKey.currentState != null) {
        state.answerMediaKey.currentState?.mediaLoad();
      }
    }
  }

  Future<void> onMediaFullScreen() async {
    state.videoFullScreen = !state.videoFullScreen;
    if (state.videoFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    update([GsCrRepeatLogic.id]);
  }

  Future<void> onMediaInited(String playerId) async {
    if (playerId == state.questionMediaId) {
      if (state.tryNeedPlayQuestion) {
        state.questionMediaKey.currentState?.moveByIndex();
      } else {
        state.questionMediaKey.currentState?.stopMove();
      }
    }

    if (playerId == state.answerMediaId) {
      if (state.tryNeedPlayAnswer) {
        state.answerMediaKey.currentState?.moveByIndex();
      } else {
        state.answerMediaKey.currentState?.stopMove();
      }
    }
  }

  Future<void> resetPnOffset() async {
    if (state.justView) {
      await setCurrentLearnContentAndUpdateView(
        index: state.justViewIndex,
        pnOffset: 0,
      );
    } else {
      await setCurrentLearnContentAndUpdateView(
        index: state.c.indexWhere((t) => t.segmentKeyId == state.currSegment.segmentKeyId),
        pnOffset: 0,
      );
    }
    state.pnOffset = 0;
  }

  Future<void> plusPnOffset() async {
    var diff = false;
    if (state.justView) {
      diff = await setCurrentLearnContentAndUpdateView(
            index: state.justViewIndex,
            pnOffset: state.pnOffset + 1,
          ) ??
          false;
    } else {
      diff = await setCurrentLearnContentAndUpdateView(
            index: state.c.indexWhere((t) => t.segmentKeyId == state.currSegment.segmentKeyId),
            pnOffset: state.pnOffset + 1,
          ) ??
          false;
    }
    if (diff) {
      ++state.pnOffset;
    }
  }

  Future<void> minusPnOffset() async {
    var diff = false;
    if (state.justView) {
      diff = await setCurrentLearnContentAndUpdateView(
            index: state.justViewIndex,
            pnOffset: state.pnOffset - 1,
          ) ??
          false;
    } else {
      diff = await setCurrentLearnContentAndUpdateView(
            index: state.c.indexWhere((t) => t.segmentKeyId == state.currSegment.segmentKeyId),
            pnOffset: state.pnOffset - 1,
          ) ??
          false;
    }
    if (diff) {
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

  void setMaskRatio(double ratio) {
    SegmentHelp.setVideoMaskRatio(state.currSegment.mediaDocPath, ratio);
    var va = VideoAttribute(state.currSegment.mediaDocPath, ratio);
    Db().db.videoAttributeDao.insertVideoAttribute(va);
  }

  double getMaskRatio() {
    if (state.justView) {
      return 0;
    }
    if (state.step != RepeatStep.recall) {
      return 0;
    }
    return SegmentHelp.getVideoMaskRatio(state.currSegment.mediaDocPath);
  }
}
