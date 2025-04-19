import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/game_server/game_server.dart';

import 'package:repeat_flutter/logic/widget/edit_progress.dart';
import 'package:repeat_flutter/logic/widget/segment_list.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/logic/repeat_logic_for_browse.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/logic/repeat_logic_for_examine.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/logic/repeat_logic.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/logic/repeat_view_for_audio.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'gs_cr_repeat_state.dart';
import 'logic/repeat_view.dart';

class GsCrRepeatLogic extends GetxController {
  static const String id = "GsCrRepeatLogic";
  final GsCrRepeatState state = GsCrRepeatState();
  GameServer server = GameServer();

  late RepeatView repeatView = RepeatViewForAudio();
  late SegmentList segmentList = SegmentList<GsCrRepeatLogic>(this);
  late RepeatLogic? repeatLogic;

  @override
  Future<void> onInit() async {
    super.onInit();
    await init();
  }

  @override
  void onClose() {
    super.onClose();
    server.stop();
    repeatLogic?.onClose();
    repeatView.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    Get.find<GsCrLogic>().init();
  }

  init() async {
    var all = Get.find<GsCrLogic>().currProgresses;
    if (Get.arguments == Repeat.justView) {
      repeatLogic = RepeatLogicForBrowse();
    } else {
      repeatLogic = RepeatLogicForExamine();
    }
    var ok = await repeatLogic!.init(all, () {
      update([GsCrRepeatLogic.id]);
    });
    if (!ok) {
      Get.back();
      return;
    }
    await state.helper.init(repeatLogic!);
    repeatView.init(state.helper);
    update([GsCrRepeatLogic.id]);
  }

  switchConcentrationMode() {
    state.concentrationMode = !state.concentrationMode;
    update([GsCrRepeatLogic.id]);
  }

  void adjustProgress() async {
    var curr = getCurr();
    if (curr == null || repeatLogic == null) {
      return;
    }
    EditProgress.show(curr.segmentKeyId, title: I18nKey.btnNext.tr, callback: (p, n) async {
      await repeatLogic!.jump(progress: p, nextDayValue: n);
      Get.back();
      update([GsCrRepeatLogic.id]);
    });
  }

  void openSegmentList() async {
    if (repeatLogic == null) {
      return;
    }
    var curr = repeatLogic!.currSegment;
    if (curr == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return;
    }
    await segmentList.show(selectSegmentKeyId: curr.segmentKeyId);
    update([GsCrRepeatLogic.id]);
  }

  void onPreClick() {
    state.needUpdateSystemUiMode = true;
  }

  SegmentTodayPrg? getCurr() {
    if (repeatLogic == null) {
      return null;
    }
    return repeatLogic!.currSegment;
  }
}
