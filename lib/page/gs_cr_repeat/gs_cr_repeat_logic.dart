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
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
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
    state.needToPlayMedia = true;
    state.fakeKnow = 0;
    await setCurrentLearnContentAndUpdateView();
  }

  void onPreClick() {
    state.needUpdateSystemUiMode = true;
  }

  void show() {
    if (ticker.isStuck()) {
      return;
    }
    state.step = RepeatStep.evaluate;
    state.needToPlayMedia = true;
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
    state.needToPlayMedia = true;
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
      RxString err = "".obs;
      var content = await SegmentHelp.from(next.segmentKeyId, err: err);
      if (err.value != "") {
        Nav.back();
        MsgBox.yes(I18nKey.btnError.tr, err.value);
        return;
      }
      state.nextKey = content!.k;
    }
  }

  void adjustProgress() async {
    var progress = "".obs;
    var curr = state.c[0];
    var schedule = await Db().db.scheduleDao.getSegmentOverallPrg(curr.segmentKeyId);
    if (schedule == null) {
      return;
    }
    MsgBox.strInputWithYesOrNo(
      progress,
      I18nKey.labelAdjustLearnProgress.tr,
      I18nKey.labelAdjustLearnProgressDesc.trArgs(["${schedule.progress}"]),
      yes: () async {
        Nav.back();
        int pv = 0;
        try {
          pv = int.parse(progress.value);
        } catch (e) {
          Snackbar.show(I18nKey.labelPleaseInputUnSignNumber.tr);
          return;
        }
        if (pv < 0) {
          Snackbar.show(I18nKey.labelPleaseInputUnSignNumber.tr);
          return;
        }
        know(autoNext: true, progress: pv);
      },
    );

    update([GsCrRepeatLogic.id]);
  }

  // TODO add device volume button
  void know({autoNext = false, int progress = -1}) async {
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
      await Db().db.scheduleDao.right(curr, progress);
    }
    if (curr.progress >= ScheduleDao.scheduleConfig.maxRepeatTime) {
      state.c.removeAt(0);
    }
    state.c.sort(schedulesCurrentSort);
    state.progress = state.total - state.c.length;
    if (autoNext && state.c.isNotEmpty) {
      state.needToPlayMedia = true;
      next(fromView: false);
    } else {
      state.needToPlayMedia = false;
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
    state.needToPlayMedia = true;
    state.fakeKnow = 0;
    await setCurrentLearnContentAndUpdateView();
  }

  void showForJustView() {
    if (ticker.isStuck()) {
      return;
    }
    state.step = RepeatStep.evaluate;
    state.needToPlayMedia = true;
    update([GsCrRepeatLogic.id]);
  }

  void nextForJustView() async {
    if (ticker.isStuck()) {
      return;
    }
    state.step = RepeatStep.recall;
    state.needToPlayMedia = true;
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
    state.needToPlayMedia = true;
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
    RxString err = "".obs;
    var learnSegment = await SegmentHelp.from(curr.segmentKeyId, offset: pnOffset, err: err);
    if (err.value != "") {
      Nav.back();
      MsgBox.yes(I18nKey.btnError.tr, err.value);
      return null;
    }
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

  List<MediaSegment> getSegments() {
    List<MediaSegment> ret = [];
    var segment = state.segment;
    var showContent = getShowContent();

    for (int i = 0; i < showContent.length; i++) {
      var sc = showContent[i];
      if (sc.contentType == ContentType.questionOrPrevAnswerOrTitleMedia) {
        if (segment.qMediaSegments.isNotEmpty) {
          ret = [segment.qMediaSegments[segment.segmentIndex]];
        } else if (segment.question == "" && segment.aMediaSegments.isNotEmpty && segment.segmentIndex - 1 >= 0) {
          ret = [segment.aMediaSegments[segment.segmentIndex - 1]];
        } else if (segment.question == "" && segment.titleMediaSegment != null) {
          ret = [segment.titleMediaSegment!];
        }
      } else if (sc.contentType == ContentType.answerMedia) {
        if (segment.mediaDocPath != "" && segment.aMediaSegments.isNotEmpty) {
          ret = [segment.aMediaSegments[segment.segmentIndex]];
        }
      }
    }
    return ret;
  }

  void mediaLoad(InitMediaCallback mediaInit) {
    if (state.skipControlMedia) {
      state.skipControlMedia = false;
      return;
    }
    state.mediaKey.currentState?.mediaLoad(mediaInit);
  }

  Future<void> onMediaInited(String playerId) async {
    if (playerId == GsCrRepeatState.mediaId) {
      if (state.needToPlayMedia) {
        state.mediaKey.currentState?.moveByIndex();
      } else {
        state.mediaKey.currentState?.stopMove();
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

  List<ContentArg> getShowContent() {
    List<List<ContentArg>> currProcessShowContent;
    var processIndex = state.progress;
    if (processIndex < 0) {
      currProcessShowContent = state.showContent[0];
    } else if (processIndex < state.showContent.length) {
      currProcessShowContent = state.showContent[processIndex];
    } else {
      currProcessShowContent = state.showContent[state.showContent.length - 1];
    }

    List<ContentArg> showContent;
    if (state.step.index < currProcessShowContent.length) {
      showContent = currProcessShowContent[state.step.index];
    } else {
      showContent = currProcessShowContent[currProcessShowContent.length - 1];
    }
    return showContent;
  }

  finish() {
    state.needToPlayMedia = false;
    state.fakeKnow = 0;
    Nav.gsCrRepeatFinish.push();
  }

  void setMaskRatio(double ratio) {
    SegmentHelp.setVideoMaskRatio(state.currSegment.mediaDocPath, ratio);
    var va = VideoAttribute(state.currSegment.mediaDocPath, ratio);
    Db().db.videoAttributeDao.insertVideoAttribute(va);
  }

  double getMaskRatio() {
    if (state.step != RepeatStep.recall) {
      return 0;
    }
    return SegmentHelp.getVideoMaskRatio(state.currSegment.mediaDocPath);
  }
}
