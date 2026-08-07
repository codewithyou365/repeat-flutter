import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/db/entity/tip.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/classroom_help.dart';
import 'package:repeat_flutter/logic/model/lazy_verse_today_prg_list.dart';
import 'package:repeat_flutter/logic/widget/text_template.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/assistive_touch_logic.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/assistive_touch_sheet.dart';
import 'package:repeat_flutter/logic/widget/gamepad/gamepad_binding_sheet.dart';
import 'package:repeat_flutter/logic/widget/gamepad/gamepad_logic.dart';
import 'package:repeat_flutter/logic/widget/edit_progress.dart';
import 'package:repeat_flutter/logic/widget/expand/expand_sheet.dart';
import 'package:repeat_flutter/logic/widget/game/game_logic.dart';
import 'package:repeat_flutter/logic/widget/quick_entry/quick_entry.dart';
import 'package:repeat_flutter/logic/widget/adjust_font.dart';
import 'package:repeat_flutter/logic/widget/webview/webview_args.dart';
import 'package:repeat_flutter/logic/widget/webview/webview_logic.dart';
import 'package:repeat_flutter/logic/widget/tip/tip_logic.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/content/content_args.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
import 'package:repeat_flutter/page/repeat/logic/tts_helper.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'repeat_args.dart';
import 'repeat_state.dart';
import 'logic/session_coordinator.dart';
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
  final WebviewLogic webviewLogic = WebviewLogic();

  RepeatLogic() {
    showTypeToRepeatView[RepeatViewEnum.audio.name] = RepeatViewForAudio();
    showTypeToRepeatView[RepeatViewEnum.text.name] = RepeatViewForText();
    showTypeToRepeatView[RepeatViewEnum.video.name] = RepeatViewForVideo();
  }

  String? _lastViewName;

  /// 三个视图是页面级常驻实例，切视图只是换了 widget 子树，上一个视图的播放器不会自动停，
  /// 所以视图类型一变就把上一个停掉（放在帧后执行，避免在 build 里改状态）。
  void onViewNameChanged(String viewName) {
    final last = _lastViewName;
    _lastViewName = viewName;
    if (last == null || last == viewName) {
      return;
    }
    final prev = showTypeToRepeatView[last];
    if (prev == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => prev.stopPlayback());
  }

  late AdjustFont adjustFont = AdjustFont<RepeatLogic>(this);
  late TextTemplate copyLogic = TextTemplate<RepeatLogic>(CrK.copyTemplate, this);
  late GameLogic<RepeatLogic> gameLogic;
  late TipLogic<RepeatLogic> tipLogic;
  late SessionCoordinator gameHelper;
  late final AssistiveTouchLogic assistiveTouchLogic = AssistiveTouchLogic(this);
  late final GamepadLogic gamepadLogic = GamepadLogic(this);

  late RepeatFlow? repeatFlow;
  final SubList bookSub = [];
  bool saveGlobalBrowsePosition = false;
  DisplayModeSource? displayModeSource;

  @override
  Future<void> onInit() async {
    super.onInit();
    await assistiveTouchLogic.loadSettings();
    await gamepadLogic.loadSettings();
    gamepadLogic.attach();
    gameLogic = GameLogic<RepeatLogic>(
      parentLogic: this,
      ttsHelper: ttsHelper,
      tapNext: onNext,
      tapLeft: onTapLeft,
      tapRight: onLongTapRight,
      tapMiddle: onTapMiddle,
      longTapMiddle: onLongTapMiddle,
    );
    tipLogic = TipLogic<RepeatLogic>(
      parentLogic: this,
      ttsHelper: ttsHelper,
      isMute: () {
        return state.helper.doNotPlayMedia;
      },
      tapNext: onNext,
      tapLeft: onTapLeft,
      tapRight: onLongTapRight,
      tapMiddle: onTapMiddle,
      longTapMiddle: onLongTapMiddle,
    );
    gameHelper = SessionCoordinator(gameLogic.web, tipLogic.web);
    ttsHelper.tryInit(TtsKeys.tip);
    copyLogic.init();
    expandSheet.init();
    expandSheet.logic.onPlayTarget = assistiveTouchLogic.playTarget;
    var args = Get.arguments as RepeatArgs;
    saveGlobalBrowsePosition = args.saveGlobalBrowsePosition;
    displayModeSource = args.displayModeSource;
    state.enableShowRecallButtons = args.enableShowRecallButtons;
    if (args.repeatFlowType == RepeatType.browse) {
      repeatFlow = RepeatFlowForBrowse();
    } else {
      repeatFlow = RepeatFlowForExamine();
    }
    await ClassroomHelp.registerRes();
    await initTips(args.progresses);
    state.gameLogicInitSuccess = await gameLogic.init(() {
      gameHelper.tryRefresh(repeatFlow!.currVerse!);
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
      QuickEntry.hideGuiding();
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
    WakelockPlus.enable();
    SystemChrome.setSystemUIChangeCallback((bool systemOverlaysAreVisible) async {
      state.systemUiVisible = systemOverlaysAreVisible;
    });
    update([RepeatLogic.id]);
    if (QuickEntry.autoOpenGame) {
      QuickEntry.autoOpenGame = false;
      await quickEntryOpenGame();
    }
    // the target screen is ready, so the quick entry guiding is over
    QuickEntry.hideGuiding();
  }

  /// Quick entry: start the game network and jump into the game webview
  /// directly, without showing the game panel.
  Future<void> quickEntryOpenGame() async {
    if (!state.gameLogicInitSuccess) {
      Snackbar.show(I18nKey.quickEntryNoGame.tr);
      return;
    }
    if (!await gameLogic.hasAdmin()) {
      await gameLogic.promptCreateAdmin(onDone: quickEntryOpenGame);
      return;
    }
    await gameLogic.switchWeb(true, popOnError: false);
    if (gameLogic.state.urls.isEmpty) {
      // the game server failed to start, the error is shown by switchWeb
      return;
    }
    // wait for the page to be mounted before switching to the webview
    WidgetsBinding.instance.addPostFrameCallback((_) {
      state.helper.stopMedia(true);
      openGameWebView(gameLogic.buildWebviewArgs());
    });
  }

  void applySystemUiMode() {
    state.systemUiVisible = false;
    if (state.helper.landscape || state.helper.focusMode.value) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    }
  }

  void restoreSystemUiIfNeeded() {
    if (!state.systemUiVisible) {
      return;
    }
    applySystemUiMode();
  }

  Future<void> initTips(List<VerseTodayPrg> progresses) async {
    final defaultTips = await Db().db.tipDao.getByClassroomId(Classroom.curr);

    Map<String, Tip> defaultTypeToTip = {};
    for (var tip in defaultTips) {
      defaultTypeToTip.putIfAbsent(tip.t, () => tip);
    }

    final bookIds = progresses is LazyVerseTodayPrgList //
        ? progresses.bookIds
        : progresses.map((p) => p.bookId).toSet();

    state.bookIdToTip = <int, Map<String, Tip?>>{};

    // 'q'/'a'/'n' 的提示服务配置放在各本书的字段块自己身上（见 ClassroomHelp.bookFieldRefs）。
    for (var bookId in bookIds) {
      final Map<String, Tip?> bookTips = {};
      state.bookIdToTip[bookId] = bookTips;

      final bookContent = await Db().db.bookDao.getContentById(bookId);
      if (bookContent == null) continue;

      final dynamic bookMap = jsonDecode(bookContent);
      if (bookMap is! Map<String, dynamic>) continue;

      for (var ref in ClassroomHelp.bookFieldRefs) {
        bookTips[ref] = _resolveTip(bookMap, ref, defaultTips, defaultTypeToTip);
      }
    }

    // 提示（'t'/'t1'/…）的提示服务配置在课堂那一层，整个课堂共用一套。
    state.classroomTips = {};
    final classroom = await Db().db.classroomDao.getById(Classroom.curr);
    final classroomContent = classroom?.content;
    if (classroomContent == null || classroomContent.isEmpty) return;
    final dynamic classroomMap = jsonDecode(classroomContent);
    if (classroomMap is! Map<String, dynamic>) return;

    final tipLength = VerseField.tipLength(classroomMap);
    for (var i = 0; i < (tipLength == 0 ? 1 : tipLength); i++) {
      final ref = VerseField.ref('t', i);
      state.classroomTips[ref] = _resolveTip(classroomMap, ref, defaultTips, defaultTypeToTip);
    }
  }

  /// 字段块里的 'i' 就是 Tip 行的 id（由 ClassroomHelp 登记时回写）。
  /// 找不到那一行就退回同名字段串的第一行，兼容还没重新登记过的内容。
  Tip? _resolveTip(
    Map<String, dynamic> content,
    String ref,
    List<Tip> tips,
    Map<String, Tip> typeToTip,
  ) {
    final entry = VerseField.of(content, ref);
    if (entry == null) return null;

    final tipId = entry['i'];
    if (tipId == null) return null;

    return tips.firstWhereOrNull((item) => item.id == tipId) ?? typeToTip[ref];
  }

  Future<void> openTip(Tip tip) async {
    var curr = getCurr();
    if (curr == null) {
      return;
    }
    await Db().db.kvDao.insertOrReplace(Kv(K.lastVerseId, '${curr.verseId}'));
    final ctx = Get.context;
    if (ctx == null) {
      return;
    }
    await tipLogic.openTipSheet(ctx, tip);
  }

  @override
  void onClose() async {
    super.onClose();
    if (saveGlobalBrowsePosition) {
      var curr = getCurr();
      if (curr != null) {
        await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.lastBrowseVerseId, '${curr.verseId}'));
      }
    }
    assistiveTouchLogic.dispose();
    gamepadLogic.detach();
    bookSub.off();
    await gameLogic.switchWeb(false);
    repeatFlow?.onClose();
    for (var v in showTypeToRepeatView.values) {
      v.dispose();
    }
    state.helper.onClose();
    await state.helper.mediaShareLogic.switchWeb(false);
    SystemChrome.setSystemUIChangeCallback(null);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    WakelockPlus.disable();
    state.helper.practiceController.dispose();
    if (state.fullScreenMode.value == RepeatFullScreenMode.closeEyes) {
      HapticFeedback.heavyImpact();
    }
  }

  void switchFocusMode() {
    state.helper.focusMode.value = !state.helper.focusMode.value;
    state.helper.tryToPlayMedia = false;
    applySystemUiMode();
    update([RepeatLogic.id]);
  }

  Future<void> openGame() async {
    state.helper.stopMedia(false);
    if (!await gameLogic.hasAdmin()) {
      await gameLogic.promptCreateAdmin(onDone: openGame);
      return;
    }
    WebviewArgs? next = await gameLogic.open();
    state.helper.stopMedia(true);
    if (next != null) {
      openGameWebView(next);
    }
  }

  void openGameWebView(WebviewArgs args) {
    state.fullScreenMode.value = RepeatFullScreenMode.gameWebView;
    state.webviewArgs = args;
  }

  void openCloseEyesMode() {
    state.fullScreenMode.value = RepeatFullScreenMode.closeEyes;
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
    repeatFlow?.refresh();
    state.helper.tryToPlayMedia = false;
    update([RepeatLogic.id]);
    var source = displayModeSource;
    if (source != null) {
      DisplayModeKv.set(Classroom.curr, source, state.helper.showMode.value);
    }
  }

  Future<void> openExpand() async {
    final verse = state.helper.getCurrVerse();
    if (verse == null) {
      return;
    }
    final map = state.helper.getCurrVerseMap();
    if (map == null) {
      return;
    }
    await expandSheet.open(verse, map);
    update([RepeatLogic.id]);
  }

  Future<void> openAssistiveTouch() async {
    await AssistiveTouchSheet.open(assistiveTouchLogic);
    update([RepeatLogic.id]);
  }

  Future<void> openGamepadBinding() async {
    await GamepadBindingSheet.open(gamepadLogic);
    update([RepeatLogic.id]);
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
    var chapter = await Db().db.chapterDao.getChapterShowById(curr.chapterId);
    if (chapter == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.tr);
      return;
    }
    state.helper.stopMedia(false);
    await Nav.content.push(
      arguments: ContentArgs(
        bookId: curr.bookId,
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
    // 悬浮球 Play-* 临时指定的字段只在原地生效，翻页/切步骤后回到按步骤走。
    state.helper.playFieldOverride = null;
    ttsHelper.stop();
  }

  void onNext() {
    preClick();
    if (repeatFlow != null) {
      repeatFlow!.onNext();
    }
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
      // 打字游戏里点击"提示"按钮或按提示快捷键(hintTrigger)都会走到这里(tapMiddle),
      // 这是用户主动要看提示的操作,应和音频/视频卡片点击播放一样解除"不自动播放媒体"标记
      state.helper.doNotPlayMedia = false;
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
