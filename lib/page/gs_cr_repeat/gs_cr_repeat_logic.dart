import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/lesson_help.dart';
import 'package:repeat_flutter/logic/widget/copy_template.dart';

import 'package:repeat_flutter/logic/widget/edit_progress.dart';
import 'package:repeat_flutter/logic/widget/segment_list.dart';
import 'package:repeat_flutter/logic/widget/web_manager.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/content/content_args.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_logic.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/logic/game_helper.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/logic/repeat_logic_for_browse.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/logic/repeat_logic_for_examine.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/logic/repeat_logic.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/logic/repeat_view_for_audio.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/logic/repeat_view_for_text.dart';
import 'package:repeat_flutter/page/gs_cr_repeat/logic/repeat_view_for_video.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'gs_cr_repeat_state.dart';
import 'logic/repeat_view.dart';

class GsCrRepeatLogic extends GetxController {
  static const String id = "GsCrRepeatLogic";
  final GsCrRepeatState state = GsCrRepeatState();
  final Map<String, RepeatView> nameToRepeatView = {};

  GsCrRepeatLogic() {
    nameToRepeatView[RepeatViewEnum.audio.name] = RepeatViewForAudio();
    nameToRepeatView[RepeatViewEnum.text.name] = RepeatViewForText();
    nameToRepeatView[RepeatViewEnum.video.name] = RepeatViewForVideo();
  }

  late CopyLogic copyLogic = CopyLogic<GsCrRepeatLogic>(CrK.copyTemplate, this);
  late SegmentList segmentList = SegmentList<GsCrRepeatLogic>(this);
  late WebManager webManager = WebManager<GsCrRepeatLogic>(this);
  late GameHelper gameHelper = GameHelper(webManager.web);

  late RepeatLogic? repeatLogic;

  @override
  Future<void> onInit() async {
    super.onInit();
    await init();
  }

  @override
  void onClose() {
    super.onClose();
    webManager.switchWeb(false);
    repeatLogic?.onClose();
    for (var v in nameToRepeatView.values) {
      v.dispose();
    }

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
    await webManager.init(() {
      gameHelper.tryRefreshGame(repeatLogic!.currSegment!);
    });
    var ok = await repeatLogic!.init(all, () {
      update([GsCrRepeatLogic.id]);
    }, gameHelper);
    if (!ok) {
      Get.back();
      return;
    }
    await state.helper.init(repeatLogic!);
    for (var v in nameToRepeatView.values) {
      v.init(state.helper);
    }
    update([GsCrRepeatLogic.id]);
  }

  switchConcentrationMode() {
    state.concentrationMode = !state.concentrationMode;
    update([GsCrRepeatLogic.id]);
  }

  switchEditMode() {
    state.helper.edit = !state.helper.edit;
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

  void openContent() async {
    var curr = getCurr();
    if (curr == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return;
    }
    var content = await Db().db.contentDao.getBySerial(curr.classroomId, curr.contentSerial);
    if (content == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return;
    }
    var lesson = LessonHelp.getCache(curr.lessonKeyId);
    if (lesson == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return;
    }
    await Nav.content.push(
      arguments: ContentArgs(
        bookName: content.name,
        initLessonSelect: lesson.lessonIndex,
        selectSegmentKeyId: curr.segmentKeyId,
        defaultTap: 2,
      ),
    );
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
