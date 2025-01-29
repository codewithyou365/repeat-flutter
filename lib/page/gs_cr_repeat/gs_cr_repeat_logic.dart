import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/common/ip.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/common/ws/message.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/game_server/game_server.dart';
import 'package:repeat_flutter/logic/schedule_help.dart';
import 'package:repeat_flutter/logic/repeat_doc_edit_help.dart';
import 'package:repeat_flutter/logic/repeat_doc_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';
import 'package:repeat_flutter/logic/widget/copy_template.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'gs_cr_repeat_state.dart';
import 'gs_cr_repeat_view_basic.dart';

class GsCrRepeatLogic extends GetxController {
  static const String id = "MainRepeatLogic";
  final GsCrRepeatState state = GsCrRepeatState();
  List<SegmentTodayPrg> todayProgresses = [];
  GameServer server = GameServer();
  late CopyLogic copyLogic = CopyLogic<GsCrRepeatLogic>(CrK.copyTemplate, this);
  Ticker ticker = Ticker(1000);

  @override
  Future<void> onInit() async {
    super.onInit();
    await init();
  }

  @override
  void onClose() {
    super.onClose();
    server.stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    Get.find<GsCrLogic>().init();
  }

  init() async {
    await copyLogic.init();
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
    setNeedToPlayMedia(true);
    state.fakeKnow = 0;
    var ignoringPunctuation = await Db().db.scheduleDao.intKv(Classroom.curr, CrK.ignoringPunctuationInTypingGame) ?? 0;
    state.ignoringPunctuation.value = ignoringPunctuation == 1;
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
    setNeedToPlayMedia(true);
    state.fakeKnow = 1;
    update([GsCrRepeatLogic.id]);
  }

  void tip() {
    state.openTip = [TipLevel.tip1];
    state.skipControlMedia = true;
    update([GsCrRepeatLogic.id]);
  }

  void tipWithAnswer() {
    state.openTip = [TipLevel.tip1, TipLevel.tip2];
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
    setNeedToPlayMedia(true);
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
    state.nextKey = "";
    SegmentTodayPrg? curr;
    SegmentTodayPrg? next;
    if (state.justView) {
      if (state.c.length > state.justViewIndex + 1) {
        curr = state.c[state.justViewIndex];
        next = state.c[state.justViewIndex + 1];
      }
    } else {
      if (state.c.length > 1) {
        curr = state.c[0];
        next = state.c[1];
      }
    }
    if (curr == null || next == null) {
      return;
    }
    if (curr.sort + 1 == next.sort) {
      return;
    }
    RxString err = "".obs;
    var content = await RepeatDocHelp.from(next.segmentKeyId, err: err);
    if (err.value != "") {
      Nav.back();
      MsgBox.yes(I18nKey.btnError.tr, err.value);
      return;
    }
    state.nextKey = content!.k;
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
  void know({autoNext = false, tryFinish = false, int progress = -1}) async {
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
      setNeedToPlayMedia(true);
      next(fromView: false);
    } else {
      setNeedToPlayMedia(false);
      state.step = RepeatStep.finish;
      if (tryFinish) {
        finish();
      } else {
        update([GsCrRepeatLogic.id]);
      }
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
    setNeedToPlayMedia(true);
    state.fakeKnow = 0;
    await setCurrentLearnContentAndUpdateView();
    await tryRefreshGame();
  }

  void showForJustView() {
    if (ticker.isStuck()) {
      return;
    }
    state.step = RepeatStep.evaluate;
    setNeedToPlayMedia(true);
    update([GsCrRepeatLogic.id]);
  }

  void nextForJustView({tryFinish = false}) async {
    if (ticker.isStuck()) {
      return;
    }
    if (state.justViewWithoutRecall) {
      state.step = RepeatStep.evaluate;
    } else {
      state.step = RepeatStep.recall;
    }

    setNeedToPlayMedia(true);
    state.fakeKnow = 0;
    if (state.justViewIndex < state.c.length - 1) {
      state.justViewIndex++;
    } else if (tryFinish) {
      finish();
    }
    await setCurrentLearnContentAndUpdateView(index: state.justViewIndex);
    await tryRefreshGame();
  }

  void previousForJustView() async {
    if (ticker.isStuck()) {
      return;
    }
    if (state.justViewWithoutRecall) {
      state.step = RepeatStep.evaluate;
    } else {
      state.step = RepeatStep.recall;
    }
    setNeedToPlayMedia(true);
    state.fakeKnow = 0;
    if (state.justViewIndex > 0) {
      state.justViewIndex--;
    }
    await setCurrentLearnContentAndUpdateView(index: state.justViewIndex);
    await tryRefreshGame();
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
    state.openTip = [];
    var oldSegmentKeyId = state.segment.segmentKeyId;
    RxString err = "".obs;
    var learnSegment = await RepeatDocHelp.from(curr.segmentKeyId, offset: pnOffset, err: err);
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
            await Db().db.scheduleDao.deleteBySegmentKeyId(learnSegment.segmentKeyId);
            Nav.gsCr.until();
          }, I18nKey.labelExecuting.tr);
        },
      );
      return null;
    }
    bool ret = true;
    if (learnSegment.segmentKeyId == oldSegmentKeyId && fromPn) {
      ret = false;
    }
    state.segment = learnSegment;
    state.segmentTodayPrg = curr;
    if (!fromPn) {
      state.currSegment = learnSegment;
    }
    update([GsCrRepeatLogic.id]);
    return ret;
  }

  List<MediaSegment> getSegments() {
    List<MediaSegment> ret = [];
    var segment = state.segment;
    var showContent = getShowContent();
    if (segment.mediaExtension == "") {
      return ret;
    }
    for (int i = 0; i < showContent.length; i++) {
      var sc = showContent[i];
      if (sc.contentType == ContentType.questionMedia) {
        if (segment.qMediaSegments.isNotEmpty) {
          ret = [segment.qMediaSegments[segment.segmentIndex]];
          state.segmentPlayType = PlayType.question;
        }
      } else if (sc.contentType == ContentType.answerMedia) {
        if (segment.aMediaSegments.isNotEmpty) {
          ret = [segment.aMediaSegments[segment.segmentIndex]];
          state.segmentPlayType = PlayType.answer;
        }
      }
    }
    return wrapSegments(ret);
  }

  List<MediaSegment> wrapSegments(List<MediaSegment> lines) {
    List<MediaSegment> ret = [];
    for (var line in lines) {
      ret.add(MediaSegment.fromDoubles(line.start, line.end + state.extendTail));
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

  bool onMediaInited(String playerId) {
    if (playerId == GsCrRepeatState.mediaId) {
      if (state.ignorePlayingMedia) {
        return false;
      }
      state.ignorePlayingMedia = true;
      if (state.needToPlayMedia) {
        state.mediaKey.currentState?.moveByIndex();
      } else {
        state.mediaKey.currentState?.stopMove();
      }
      return true;
    }
    return false;
  }

  Future<void> resetPnOffset() async {
    setNeedToPlayMedia(true);
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
    setNeedToPlayMedia(true);
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
    setNeedToPlayMedia(true);
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
    Nav.gsCr.until();
  }

  void setMaskRatio(double ratio) {
    RepeatDocEditHelp.setVideoMaskRatio(state.segment, ratio);
  }

  double getMaskRatio() {
    if (state.step != RepeatStep.recall) {
      return 0;
    }
    if (state.openTip.contains(TipLevel.tip2)) {
      return 0;
    }
    var segment = state.segment;
    return RepeatDocHelp.getVideoMaskRatio(segment.contentSerial, segment.lessonIndex, segment.mediaExtension);
  }

  openGameMode(BuildContext context) async {
    if (state.gameMode == false) {
      state.gamePort = await server.start();
      state.gameMode = true;
      tryRefreshGame();
    }
    try {
      state.gameAddress = [];
      final ips = await Ip.getLanIps();
      for (var i = 0; i < ips.length; i++) {
        String ip = ips[i];
        state.gameAddress.add('http://$ip:${state.gamePort}');
      }
    } catch (e) {
      Snackbar.show('Error getting LAN IP : $e');
      return;
    }
    GsCrRepeatViewBasic.showGameAddress(context, this);
  }

  tryRefreshGame() async {
    if (!state.gameMode) {
      return;
    }
    var now = DateTime.now();
    var stp = state.segmentTodayPrg;
    stp.time += 1;
    var game = Game(
      stp.id!,
      stp.time,
      state.segment.mediaHash,
      state.segment.aStart,
      state.segment.aEnd,
      state.segment.word,
      state.segment.segmentKeyId,
      state.segment.classroomId,
      state.segment.contentSerial,
      state.segment.lessonIndex,
      state.segment.segmentIndex,
      false,
      now.millisecondsSinceEpoch,
      Date.from(now),
    );
    await Db().db.gameDao.tryInsertGame(game);
    server.server.broadcast(Request(path: Path.refreshGame, data: {"id": stp.id, "time": stp.time}));
  }

  setIgnoringPunctuation(bool ignorePunctuation) {
    state.ignoringPunctuation.value = ignorePunctuation;
    Db().db.scheduleDao.insertKv(CrKv(Classroom.curr, CrK.ignoringPunctuationInTypingGame, ignorePunctuation ? '1' : '0'));
  }

  openEditor() {
    state.extendTail = 0;
    state.edit = true;
    state.justView = true;
    state.concentrationMode = false;
    update([GsCrRepeatLogic.id]);
  }

  switchConcentrationMode() {
    state.concentrationMode = !state.concentrationMode;
    update([GsCrRepeatLogic.id]);
  }

  extendTail() {
    state.extendTail += 500;
    update([GsCrRepeatLogic.id]);
  }

  resetTail() {
    state.extendTail = 0;
    update([GsCrRepeatLogic.id]);
  }

  edit(EditType type) async {
    if (state.mediaKey.currentState == null) {
      return;
    }
    var pos = await state.mediaKey.currentState!.getMediaCurrentPosition();
    if (pos == null) {
      return;
    }
    var duration = await state.mediaKey.currentState!.getMediaDuration();
    if (duration == null) {
      return;
    }
    setNeedToPlayMedia(true);
    SegmentEditHelpOutArg outArg = SegmentEditHelpOutArg(0);
    await RepeatDocEditHelp.edit(state.segment, type, state.segmentPlayType, pos, duration, out: outArg);
    if (type == EditType.cut) {
      int? count = await Db().db.scheduleDao.lessonCount(Classroom.curr, state.segment.contentSerial, state.segment.lessonIndex);
      if (count == null || count < outArg.segmentCount + 1) {
        var ret = await ScheduleHelp.addMaterialToScheduleByContentSerial(state.segment.contentSerial);
        if (ret == false) {
          return;
        }
      }
    }
    await refreshView();
  }

  refreshView() async {
    if (state.justView) {
      await setCurrentLearnContentAndUpdateView(
        index: state.justViewIndex,
        pnOffset: state.pnOffset,
      );
    } else {
      await setCurrentLearnContentAndUpdateView(
        index: state.c.indexWhere((t) => t.segmentKeyId == state.currSegment.segmentKeyId),
        pnOffset: state.pnOffset,
      );
    }
  }

  setNeedToPlayMedia(bool v) {
    state.needToPlayMedia = v;
    state.ignorePlayingMedia = false;
  }
}
