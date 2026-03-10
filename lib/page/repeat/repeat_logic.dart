import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/chapter_help.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/classroom_help.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/logic/widget/book_editor/book_editor_args.dart';
import 'package:repeat_flutter/logic/widget/text_template.dart';
import 'package:repeat_flutter/logic/widget/edit_progress.dart';
import 'package:repeat_flutter/logic/widget/expand/expand_sheet.dart';
import 'package:repeat_flutter/logic/widget/game/game_logic.dart';
import 'package:repeat_flutter/logic/widget/adjust_font.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/logic/widget/book_editor/book_editor_logic.dart';
import 'package:repeat_flutter/page/content/content_args.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
import 'package:repeat_flutter/page/repeat/logic/tts_helper.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'repeat_args.dart';
import 'repeat_state.dart';
import 'logic/game_helper.dart';
import 'logic/repeat_flow_for_browse.dart';
import 'logic/repeat_flow_for_examine.dart';
import 'logic/repeat_flow.dart';
import 'logic/repeat_view_for_audio.dart';
import 'logic/repeat_view_for_text.dart';
import 'logic/repeat_view_for_video.dart';
import 'logic/repeat_view.dart';

class RepeatLogic extends GetxController {
  static const String id = "RepeatLogic";
  final RepeatState state = RepeatState();
  final Map<String, RepeatView> showTypeToRepeatView = {};
  final TtsHelper ttsHelper = TtsHelper();
  final ExpandSheet expandSheet = ExpandSheet();

  RepeatLogic() {
    showTypeToRepeatView[RepeatViewEnum.audio.name] = RepeatViewForAudio();
    showTypeToRepeatView[RepeatViewEnum.text.name] = RepeatViewForText();
    showTypeToRepeatView[RepeatViewEnum.video.name] = RepeatViewForVideo();
  }

  late AdjustFont adjustFont = AdjustFont<RepeatLogic>(this);
  late TextTemplate copyLogic = TextTemplate<RepeatLogic>(CrK.copyTemplate, this);
  late GameLogic<RepeatLogic> gameLogic;
  late GameHelper gameHelper;
  late BookEditorLogic bookEditor = BookEditorLogic<RepeatLogic>(this);

  late RepeatFlow? repeatFlow;
  final SubList bookSub = [];

  @override
  Future<void> onInit() async {
    super.onInit();
    gameLogic = GameLogic<RepeatLogic>(
      parentLogic: this,
      tapLeft: onTapLeft,
      tapRight: onLongTapRight,
      tapMiddle: onTapMiddle,
      longTapMiddle: onLongTapMiddle,
    );
    gameHelper = GameHelper(gameLogic.web);
    ttsHelper.init();
    copyLogic.init();
    expandSheet.init(copyLogic);
    var args = Get.arguments as RepeatArgs;
    state.enableShowRecallButtons = args.enableShowRecallButtons;
    if (args.repeatFlowType == RepeatType.browse) {
      repeatFlow = RepeatFlowForBrowse();
    } else {
      repeatFlow = RepeatFlowForExamine();
    }

    await ClassroomHelp.registerRes();
    state.gameLogicInitSuccess = await gameLogic.init(() {
      gameHelper.tryRefreshGame(repeatFlow!.currVerse!);
    });
    state.helper.showMode.value = args.showMode;
    var ok = await repeatFlow!.init(
      progresses: args.progresses,
      startIndex: args.startIndex,
      update: () {
        update([RepeatLogic.id]);
      },
      gameHelper: gameHelper,
      helper: state.helper,
    );
    if (!ok) {
      Get.back();
      return;
    }

    if (args.showMode == ShowMode.edit) {
      state.helper.focusMode.value = false;
      state.needUpdateSystemUiMode = true;
    }
    await state.helper.init(repeatFlow!);
    for (var v in showTypeToRepeatView.values) {
      v.init(state.helper);
    }
    bookSub.on([EventTopic.reimportBook], (_) {
      update([RepeatLogic.id]);
    });
    state.closeEyesDirect = await Db().db.kvDao.getIntWithDefault(K.closeEyesDirect, 0);
    update([RepeatLogic.id]);
  }

  @override
  void onClose() async {
    super.onClose();
    bookSub.off();
    await gameLogic.switchWeb(false);
    repeatFlow?.onClose();
    for (var v in showTypeToRepeatView.values) {
      v.dispose();
    }
    state.helper.onClose();
    await state.helper.mediaShareLogic.switchWeb(false);
    await bookEditor.switchWeb(false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    state.helper.practiceController.dispose();
    if (state.enableCloseEyesMode.value != CloseEyesModeEnum.none) {
      HapticFeedback.heavyImpact();
    }
  }

  void switchFocusMode() {
    state.helper.focusMode.value = !state.helper.focusMode.value;
    state.helper.tryToPlayMedia = false;
    update([RepeatLogic.id]);
  }

  void openCloseEyesMode() async {
    state.enableCloseEyesMode.value = CloseEyesModeEnum.opacity;
  }

  void switchShowMode() {
    switch (state.helper.showMode.value) {
      case ShowMode.closedBook:
        state.helper.showMode.value = ShowMode.openBook;
        break;
      case ShowMode.openBook:
        state.helper.tip = TipLevel.tip;
        state.helper.showMode.value = ShowMode.edit;
        break;
      default:
        state.helper.showMode.value = ShowMode.closedBook;
        break;
    }
    state.helper.tryToPlayMedia = false;
    update([RepeatLogic.id]);
  }

  void openAdvancedEditor() async {
    var curr = getCurr();
    if (curr == null) {
      return;
    }
    var verse = VerseHelp.getCache(curr.verseId);
    if (verse == null) {
      return;
    }
    state.helper.stopMedia(false);
    await bookEditor.open(
      BookEditorArgs(
        bookId: verse.bookId,
        chapterIndex: verse.chapterIndex,
        verseIndex: verse.verseIndex,
      ),
    );
    state.helper.stopMedia(true);
  }

  void adjustProgress() async {
    var curr = getCurr();
    if (curr == null || repeatFlow == null) {
      return;
    }
    state.helper.stopMedia(false);
    await EditProgress.show(
      curr.verseId,
      title: I18nKey.btnNext.tr,
      callback: (p, n) async {
        await repeatFlow!.jump(progress: p, nextDayValue: n);
        Get.back();
        update([RepeatLogic.id]);
      },
    );
    state.helper.stopMedia(true);
  }

  void openContent() async {
    var curr = getCurr();
    if (curr == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return;
    }
    var content = await Db().db.bookDao.getById(curr.bookId);
    if (content == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return;
    }
    var chapter = ChapterHelp.getCache(curr.chapterId);
    if (chapter == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return;
    }
    state.helper.stopMedia(false);
    await Nav.content.push(
      arguments: ContentArgs(
        bookName: content.name,
        initChapterSelect: chapter.chapterIndex,
        selectVerseKeyId: curr.verseId,
        defaultTap: 2,
      ),
    );
    state.helper.stopMedia(true);
    update([RepeatLogic.id]);
  }

  void preClick() {
    state.helper.enableReloadMedia = true;
    state.needUpdateSystemUiMode = true;
    state.helper.tryToPlayMedia = true;
    ttsHelper.stop();
  }

  void onTapLeft() {
    preClick();
    if (repeatFlow != null) {
      repeatFlow!.onTapLeft();
    }
  }

  void onTapRight() {
    preClick();
    if (repeatFlow != null) {
      repeatFlow!.onTapRight();
    }
  }

  void onLongTapRight() {
    preClick();
    if (repeatFlow != null) {
      repeatFlow!.onLongTapRight();
    }
  }

  void onTapMiddle() {
    preClick();
    if (state.helper.tip == TipLevel.tip) {
      state.helper.tip = TipLevel.none;
    } else {
      state.helper.tip = TipLevel.tip;
    }
    update([RepeatLogic.id]);
  }

  void onLongTapMiddle() async {
    preClick();
    state.helper.tip = TipLevel.tip;
    state.helper.stopMedia(true);
    update([RepeatLogic.id]);
    ttsHelper.speak(state.helper);
  }

  VerseTodayPrg? getCurr() {
    if (repeatFlow == null) {
      return null;
    }
    return repeatFlow!.currVerse;
  }

  void togglePracticeMode() {
    state.isPracticeMode.value = !state.isPracticeMode.value;
    if (!state.isPracticeMode.value) {
      state.helper.practiceController.clear();
    }
  }
}
