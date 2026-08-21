import 'dart:async';

import 'dart:convert' as convert;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/ai/ai_record_entry.dart';
import 'package:repeat_flutter/logic/ai/ai_support.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/book_cache_version.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';
import 'package:repeat_flutter/logic/model/lazy_verse_today_prg_list.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/widget/full_custom.dart';
import 'package:repeat_flutter/logic/widget/quick_entry/quick_entry.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
import 'package:repeat_flutter/page/repeat/repeat_args.dart';
import 'package:repeat_flutter/page/sc_cr_stats/sc_cr_stats_logic.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/select/select.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'logic/learning_settings.dart';
import 'sc_cr_state.dart';

class ScCrLogic extends GetxController {
  static const String id = "ScCrLogic";
  final ScCrState state = ScCrState();
  late FullCustom fullCustom = FullCustom<ScCrLogic>(this);
  final SubList initSub = [];
  final SubList<int> bookVersionSub = [];
  final SubList<ChapterShow> bookVersionWithChapterSub = [];
  final SubList<VerseShow> bookVersionWithVerseSub = [];
  Timer? timer;

  @override
  void onInit() {
    super.onInit();
    initSub.on([EventTopic.reimportBook, EventTopic.deleteBook, EventTopic.deleteChapter, EventTopic.deleteVerse], (_) {
      init();
    });

    bookVersionSub.on([EventTopic.createBook, EventTopic.importBook, EventTopic.reimportBook, EventTopic.deleteBook, EventTopic.updateBookContent], (int? bookId) {
      if (bookId != null) {
        BookCacheVersion.inc(bookId);
      }
    });

    bookVersionWithChapterSub.on([EventTopic.addChapter, EventTopic.deleteChapter, EventTopic.updateChapterContent], (ChapterShow? chapterShow) {
      if (chapterShow == null) return;
      BookCacheVersion.inc(chapterShow.bookId);
    });

    bookVersionWithVerseSub.on([EventTopic.addVerse, EventTopic.deleteVerse, EventTopic.updateVerseContent, EventTopic.updateVerseProgress], (VerseShow? verseShow) {
      if (verseShow == null) return;
      BookCacheVersion.inc(verseShow.bookId);
    });
    ScCrStatsLogic.onEvent();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await showTransparentOverlay(() async {
        await init();
        startTimer();
      });
      await runQuickEntry();
    });
  }

  @override
  void onClose() {
    super.onClose();
    initSub.off();
    bookVersionSub.off();
    bookVersionWithChapterSub.off();
    bookVersionWithVerseSub.off();
    ScCrStatsLogic.offEvent();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    stopTimer();
  }

  Future<void> init({TodayPrgType? type}) async {
    List<VerseTodayPrg> allProgresses = [];
    if (type == null) {
      allProgresses = await Db().db.scheduleDao.initToday();
    } else {
      allProgresses = await Db().db.scheduleDao.forceInitToday(type);
    }

    state.all = allProgresses;
    state.fullCustom = [];
    state.review = [];
    state.learn = [];
    state.verses = [];
    String? fullCustomJsonStr = await Db().db.scheduleDao.stringKv(Classroom.curr, CrK.todayFullCustomScheduleConfigCount);
    List<List<String>> fullCustomConfigs = ListUtil.toListList(fullCustomJsonStr);
    var configInUseJsonStr = await Db().db.scheduleDao.stringKv(Classroom.curr, CrK.todayScheduleConfigInUse);
    ScheduleConfig? scheduleConfig;
    if (configInUseJsonStr != null) {
      try {
        Map<String, dynamic> configJson = convert.jsonDecode(configInUseJsonStr);
        scheduleConfig = ScheduleConfig.fromJson(configJson);
      } catch (_) {}
    } else {
      scheduleConfig = ScheduleDao.scheduleConfig;
    }
    scheduleConfig ??= ScheduleDao.scheduleConfig;
    List<VerseTodayPrgInView> learn = [];
    List<VerseTodayPrgInView> review = [];
    List<VerseTodayPrgInView> fullCustom = [];
    Map<int, VerseTodayPrgInView> typeToVerse = {};
    for (var item in allProgresses) {
      var prgTypeAndIndex = VerseTodayPrg.getPrgTypeAndIndex(item.type);

      VerseTodayPrgInView view;
      if (typeToVerse.containsKey(prgTypeAndIndex)) {
        view = typeToVerse[prgTypeAndIndex]!;
      } else {
        view = VerseTodayPrgInView([]);
        typeToVerse[prgTypeAndIndex] = view;
      }
      view.verses.add(item);
    }
    int uniqIndex = 0;
    for (var index = 0; index < scheduleConfig.learnConfigs.length; index++) {
      var prgTypeAndIndex = VerseTodayPrg.toPrgTypeAndIndex(TodayPrgType.learn, index);
      var learnedTotalCount = 0;
      var learnTotalCount = 0;
      VerseTodayPrgInView rule;
      if (typeToVerse.containsKey(prgTypeAndIndex)) {
        rule = typeToVerse[prgTypeAndIndex]!;
        learnedTotalCount = VerseTodayPrg.getFinishedCount(rule.verses);
        learnTotalCount = rule.verses.length;
      } else {
        rule = VerseTodayPrgInView([]);
      }
      var config = scheduleConfig.learnConfigs.elementAt(index);
      rule.index = index;
      rule.uniqIndex = uniqIndex++;
      rule.type = TodayPrgType.learn;
      rule.name = config.title == "" ? "R$index: $learnedTotalCount/$learnTotalCount" : "${config.title}: $learnedTotalCount/$learnTotalCount";
      rule.desc = config.tr();
      learn.add(rule);
      state.learn.addAll(rule.verses);
    }
    for (var index = 0; index < scheduleConfig.reviewLearnConfigs.length; index++) {
      var prgTypeAndIndex = VerseTodayPrg.toPrgTypeAndIndex(TodayPrgType.review, index);
      var learnedTotalCount = 0;
      var learnTotalCount = 0;
      VerseTodayPrgInView rule;
      if (typeToVerse.containsKey(prgTypeAndIndex)) {
        rule = typeToVerse[prgTypeAndIndex]!;
        learnedTotalCount = VerseTodayPrg.getFinishedCount(rule.verses);
        learnTotalCount = rule.verses.length;
      } else {
        rule = VerseTodayPrgInView([]);
      }
      var config = scheduleConfig.reviewLearnConfigs.elementAt(index);
      rule.index = index;
      rule.uniqIndex = uniqIndex++;
      rule.type = TodayPrgType.review;
      rule.name = config.title == "" ? "R$index: $learnedTotalCount/$learnTotalCount" : "${config.title}: $learnedTotalCount/$learnTotalCount";
      rule.desc = config.tr();
      review.add(rule);
      state.review.addAll(rule.verses);
    }
    for (var index = 0; index < fullCustomConfigs.length; index++) {
      var prgTypeAndIndex = VerseTodayPrg.toPrgTypeAndIndex(TodayPrgType.fullCustom, index);
      var learnedTotalCount = 0;
      var learnTotalCount = 0;
      VerseTodayPrgInView rule;
      if (typeToVerse.containsKey(prgTypeAndIndex)) {
        rule = typeToVerse[prgTypeAndIndex]!;
        learnedTotalCount = VerseTodayPrg.getFinishedCount(rule.verses);
        learnTotalCount = rule.verses.length;
      } else {
        rule = VerseTodayPrgInView([]);
      }
      rule.index = index;
      rule.uniqIndex = uniqIndex++;
      rule.type = TodayPrgType.fullCustom;
      rule.name = "$index: $learnedTotalCount/$learnTotalCount";
      rule.desc = I18nKey.labelFullCustomConfig.trParams(fullCustomConfigs[index]);
      fullCustom.add(rule);
      state.fullCustom.addAll(rule.verses);
    }
    state.verses.addAll(learn);
    state.verses.addAll(review);
    state.verses.addAll(fullCustom);

    state.learnDeadline = ScheduleDao.nextDateTime().millisecondsSinceEpoch;
    resetLearnDeadline();

    state.learnedTotalCount = VerseTodayPrg.getFinishedCount(allProgresses);
    state.learnTotalCount = allProgresses.length;

    for (var l in learn) {
      var learnedTotalCount = VerseTodayPrg.getFinishedCount(state.learn);
      var learnTotalCount = state.learn.length;
      l.groupDesc = "${toGroupName(TodayPrgType.learn)}: $learnedTotalCount/$learnTotalCount";
    }

    for (var l in review) {
      var learnedTotalCount = VerseTodayPrg.getFinishedCount(state.review);
      var learnTotalCount = state.review.length;
      l.groupDesc = "${toGroupName(TodayPrgType.review)}: $learnedTotalCount/$learnTotalCount";
    }

    for (var l in fullCustom) {
      var learnedTotalCount = VerseTodayPrg.getFinishedCount(state.fullCustom);
      var learnTotalCount = state.fullCustom.length;
      l.groupDesc = "${toGroupName(TodayPrgType.fullCustom)}: $learnedTotalCount/$learnTotalCount";
    }

    state.all.sort((a, b) => a.sort.compareTo(b.sort));
    state.learn.sort((a, b) => a.sort.compareTo(b.sort));
    state.review.sort((a, b) => a.sort.compareTo(b.sort));
    state.fullCustom.sort((a, b) => a.sort.compareTo(b.sort));

    update([ScCrLogic.id]);
  }

  /// Walk the path the user would tap by hand, according to the quick entry
  /// configured in this classroom.
  Future<void> runQuickEntry() async {
    var type = QuickEntry.pending;
    QuickEntry.pending = null;
    if (type == null || type == QuickEntryType.none) {
      QuickEntry.hideGuiding();
      return;
    }
    QuickEntry.autoOpenGame = type.withGame;
    switch (type.content) {
      case QuickEntryType.globalBrowse:
        await globalBrowse();
        break;
      case QuickEntryType.examine:
        await tryStartAll();
        break;
      case QuickEntryType.browse:
        await tryStartAll(mode: RepeatType.browse);
        break;
      case QuickEntryType.recordTranslate:
        await recordTranslate();
        break;
      default:
        break;
    }
    QuickEntry.autoOpenGame = false;
    QuickEntry.hideGuiding();
  }

  /// 快速进入息屏录音建章。录音页要一本书，而这里没有书本上下文，
  /// 所以按课堂里配的 [RecordBookPick] 挑一本；只有一本时不问，直接进。
  Future<void> recordTranslate() async {
    if (!AiSupport.available) {
      QuickEntry.hideGuiding();
      return;
    }
    // 按 sort 排，和素材页里看到的顺序一致——"第一本/最后一本"指的就是那个顺序
    var books = await Db().db.bookDao.getAll(Classroom.curr);
    if (books.isEmpty) {
      QuickEntry.hideGuiding();
      Snackbar.show(I18nKey.labelNoContent.tr);
      return;
    }
    Book book;
    if (books.length == 1) {
      book = books.first;
    } else {
      switch (await QuickEntry.getBookPick(Classroom.curr)) {
        case RecordBookPick.first:
          book = books.first;
          break;
        case RecordBookPick.last:
          book = books.last;
          break;
        case RecordBookPick.ask:
          // 要用户动手了，引导条先撤，不然它会压在选择表上
          QuickEntry.hideGuiding();
          var index = await Select.showSheet(
            title: I18nKey.quickEntryRecordBook.tr,
            // 书本数量没上限，autoHeight 会按行数算出超过屏幕的高度，只能定高滚动
            autoHeight: false,
            keys: books.map((e) => e.name).toList(),
          );
          if (index == null) {
            return;
          }
          book = books[index];
          break;
      }
    }
    // 必须在 push 之前撤：录音页不是 repeat 页，没有 RepeatLogic 那样的消费方，
    // 而 runQuickEntry 末尾那次 hideGuiding 要等录音页 pop 之后才跑得到。
    QuickEntry.hideGuiding();
    await AiRecordEntry.open(book);
  }

  Future<void> tryStartAll({RepeatType mode = RepeatType.examine}) {
    return tryStart(state.all, mode: mode);
  }

  void tryStartGroup(TodayPrgType type, {RepeatType mode = RepeatType.examine}) {
    if (type == TodayPrgType.learn) {
      tryStart(state.learn, mode: mode);
    } else if (type == TodayPrgType.review) {
      tryStart(state.review, mode: mode);
    } else if (type == TodayPrgType.fullCustom) {
      tryStart(state.fullCustom, mode: mode);
    }
  }

  String toGroupName(TodayPrgType type) {
    if (type == TodayPrgType.learn) {
      return I18nKey.btnLearn.tr;
    } else if (type == TodayPrgType.review) {
      return I18nKey.btnReview.tr;
    } else {
      return I18nKey.btnFullCustom.tr;
    }
  }

  Future<void> tryStart(List<VerseTodayPrg> list, {bool grouping = false, RepeatType mode = RepeatType.examine}) async {
    if (list.isEmpty) {
      QuickEntry.hideGuiding();
      Snackbar.show(I18nKey.labelNoLearningContent.tr);
      return;
    }
    if (grouping) {
      list = VerseTodayPrg.getFirstUnfinishedGroup(list);
    }
    if (mode == RepeatType.examine) {
      var learnedTotalCount = VerseTodayPrg.getFinishedCount(list);
      var learnTotalCount = list.length;
      if (learnTotalCount - learnedTotalCount == 0) {
        QuickEntry.hideGuiding();
        Snackbar.show(I18nKey.labelNoLearningContent.tr);
        return;
      }
    }
    var displayModeSource = mode == RepeatType.examine ? DisplayModeSource.examine : DisplayModeSource.browse;
    var repeat = RepeatArgs(
      progresses: list,
      startIndex: 0,
      repeatFlowType: mode,
      enableShowRecallButtons: true,
      showMode: await DisplayModeKv.get(Classroom.curr, displayModeSource),
      displayModeSource: displayModeSource,
    );
    await Nav.repeat.push(arguments: repeat);
    await init();
  }

  void resetLearnDeadline() {
    var now = DateTime.now();
    if (now.millisecondsSinceEpoch < state.learnDeadline) {
      state.learnDeadlineTips = I18nKey.labelResetLearningContent.trArgs([formatHm(state.learnDeadline - now.millisecondsSinceEpoch)]);
    } else {
      state.learnDeadlineTips = "";
    }
  }

  void startTimer() {
    if (timer != null) {
      timer!.cancel();
    }
    const duration = Duration(minutes: 1);
    timer = Timer.periodic(duration, (Timer timer) {
      resetLearnDeadline();
    });
  }

  void stopTimer() {
    if (timer != null) {
      timer!.cancel();
    }
  }

  void config(TodayPrgType type) async {
    if (type == TodayPrgType.fullCustom) {
      return;
    }
    showTransparentOverlay(() async {
      learningSettings();
      await Future.delayed(const Duration(milliseconds: 300));
    });
    if (type == TodayPrgType.learn) {
      Nav.scCrSettingsEl.push();
    } else {
      Nav.scCrSettingsRel.push();
    }
  }

  void resetSchedule(TodayPrgType type) async {
    var desc = '';
    switch (type) {
      case TodayPrgType.learn:
        desc = I18nKey.labelResetLearnDesc.tr;
        break;
      case TodayPrgType.review:
        desc = I18nKey.labelResetReviewDesc.tr;
        break;
      case TodayPrgType.fullCustom:
        desc = I18nKey.labelResetFullCustomDesc.tr;
        break;
      default:
        break;
    }
    MsgBox.yesOrNo(
      title: I18nKey.labelReset.tr,
      desc: desc,
      yes: () {
        showOverlay(() async {
          await init(type: type);
          Nav.back();
          Snackbar.show(I18nKey.labelFinish.tr);
        }, I18nKey.labelExecuting.tr);
      },
    );
  }

  void resetAllSchedule() {
    showOverlay(() async {
      await Db().db.scheduleDao.deleteKv(CrKv(Classroom.curr, CrK.todayScheduleCreateDate, ""));
      await init();
      Nav.back();
      Snackbar.show(I18nKey.labelFinish.tr);
    }, I18nKey.labelExecuting.tr);
  }

  // for add schedule
  void openFullCustom(BuildContext context) {
    fullCustom.show(context, () {
      init();
    });
  }

  Future<void> globalBrowse() async {
    // 全课堂浏览，只要定位和排序 —— 正文由播放页按当前这一节现取，别在这里全量拉进来
    var verses = await Db().db.scheduleDao.getAllVerseBrief(Classroom.curr);
    if (verses.isEmpty) {
      QuickEntry.hideGuiding();
      Snackbar.show(I18nKey.mediaEmpty.tr);
      return;
    }
    verses.sort((a, b) => a.toSort().compareTo(b.toSort()));
    var startIndex = 0;
    var lastVerseId = await Db().db.crKvDao.getInt(Classroom.curr, CrK.lastBrowseVerseId);
    if (lastVerseId != null) {
      var idx = verses.indexWhere((v) => v.verseId == lastVerseId);
      if (idx >= 0) {
        startIndex = idx;
      }
    }
    await Nav.repeat.push(
      arguments: RepeatArgs(
        progresses: LazyVerseTodayPrgList(verses),
        startIndex: startIndex,
        repeatFlowType: RepeatType.browse,
        enableShowRecallButtons: false,
        showMode: await DisplayModeKv.get(Classroom.curr, DisplayModeSource.globalBrowse),
        saveGlobalBrowsePosition: true,
        displayModeSource: DisplayModeSource.globalBrowse,
      ),
    );
  }
}
