import 'dart:async';
import 'dart:convert' show jsonEncode;

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
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/logic/widget/book_editor/book_editor_args.dart';
import 'package:repeat_flutter/logic/widget/copy_template.dart';

import 'package:repeat_flutter/logic/widget/edit_progress.dart';
import 'package:repeat_flutter/logic/widget/game/game_logic.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/logic/widget/book_editor/book_editor_logic.dart';
import 'package:repeat_flutter/page/content/content_args.dart';
import 'package:repeat_flutter/page/editor/editor_args.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
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

  RepeatLogic() {
    showTypeToRepeatView[RepeatViewEnum.audio.name] = RepeatViewForAudio();
    showTypeToRepeatView[RepeatViewEnum.text.name] = RepeatViewForText();
    showTypeToRepeatView[RepeatViewEnum.video.name] = RepeatViewForVideo();
  }

  late CopyLogic copyLogic = CopyLogic<RepeatLogic>(CrK.copyTemplate, this);
  late GameLogic gameLogic = GameLogic<RepeatLogic>(this);
  late GameHelper gameHelper = GameHelper(gameLogic.web);
  late BookEditorLogic bookEditor = BookEditorLogic<RepeatLogic>(this);

  late RepeatFlow? repeatLogic;
  final SubList bookSub = [];

  @override
  Future<void> onInit() async {
    super.onInit();
    var args = Get.arguments as RepeatArgs;
    state.enableShowRecallButtons = args.enableShowRecallButtons;
    if (args.repeatType == RepeatType.justView) {
      repeatLogic = RepeatFlowForBrowse();
    } else {
      repeatLogic = RepeatFlowForExamine();
    }
    await gameLogic.init(() {
      gameHelper.tryRefreshGame(repeatLogic!.currVerse!);
    });
    state.helper.showMode.value = args.showMode;
    var ok = await repeatLogic!.init(
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
    await state.helper.init(repeatLogic!);
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
  void onClose() {
    super.onClose();
    bookSub.off();
    gameLogic.switchWeb(false);
    repeatLogic?.onClose();
    for (var v in showTypeToRepeatView.values) {
      v.dispose();
    }
    state.helper.onClose();
    state.helper.closeMediaShareWeb();
    bookEditor.switchWeb(false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    if (state.enableCloseEyesMode.value != CloseEyesModeEnum.none) {
      HapticFeedback.heavyImpact();
    }
  }

  void switchFocusMode() {
    state.helper.focusMode.value = !state.helper.focusMode.value;
    state.helper.enablePlayingPlayMedia = false;
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
        state.helper.showMode.value = ShowMode.edit;
        break;
      default:
        state.helper.showMode.value = ShowMode.closedBook;
        break;
    }
    state.helper.enablePlayingPlayMedia = false;
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
    state.helper.setInRepeatView(false);
    await bookEditor.open(
      BookEditorArgs(
        bookId: verse.bookId,
        bookName: verse.bookName,
        chapterIndex: verse.chapterIndex,
        verseIndex: verse.verseIndex,
      ),
    );
    state.helper.setInRepeatView(true);
  }

  void adjustProgress() async {
    var curr = getCurr();
    if (curr == null || repeatLogic == null) {
      return;
    }
    state.helper.setInRepeatView(false);
    await EditProgress.show(
      curr.verseId,
      title: I18nKey.btnNext.tr,
      callback: (p, n) async {
        await repeatLogic!.jump(progress: p, nextDayValue: n);
        Get.back();
        update([RepeatLogic.id]);
      },
    );
    state.helper.setInRepeatView(true);
  }

  void editNote() async {
    var curr = getCurr();
    if (curr == null || repeatLogic == null) {
      return;
    }
    Map<String, dynamic>? map = state.helper.getCurrVerseMap();
    if (map == null) {
      return;
    }
    String acronym = 'n';
    String noteStr = map[acronym] ?? '';
    state.helper.setInRepeatView(false);
    await Nav.editor.push(
      arguments: EditorArgs(
        onHistory: null,
        title: I18nKey.labelNote.tr,
        value: noteStr,
        save: (str) async {
          map[acronym] = str;
          String jsonStr = jsonEncode(map);
          var verseId = state.helper.getCurrVerse()!.verseId;
          await Db().db.verseDao.updateVerseContent(verseId, jsonStr);
        },
      ),
    );
    state.helper.setInRepeatView(true);
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
    state.helper.setInRepeatView(false);
    await Nav.content.push(
      arguments: ContentArgs(
        bookName: content.name,
        initChapterSelect: chapter.chapterIndex,
        selectVerseKeyId: curr.verseId,
        defaultTap: 2,
      ),
    );
    state.helper.setInRepeatView(true);
    update([RepeatLogic.id]);
  }

  void preClick() {
    state.needUpdateSystemUiMode = true;
    state.helper.enablePlayingPlayMedia = true;
  }

  void onTapLeft() {
    preClick();
    if (repeatLogic != null) {
      repeatLogic!.onTapLeft();
    }
  }

  void onTapRight() {
    preClick();
    if (repeatLogic != null) {
      repeatLogic!.onTapRight();
    }
  }

  void onLongTapRight() {
    preClick();
    if (repeatLogic != null) {
      repeatLogic!.onLongTapRight();
    }
  }

  void onTapMiddle() {
    preClick();
    if (repeatLogic != null) {
      repeatLogic!.onTapMiddle();
    }
  }

  VerseTodayPrg? getCurr() {
    if (repeatLogic == null) {
      return null;
    }
    return repeatLogic!.currVerse;
  }
}
