import 'dart:async';

import 'dart:convert' as convert;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/dao/book_dao.dart';
import 'package:repeat_flutter/db/dao/chapter_dao.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/dao/verse_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/book_help.dart';
import 'package:repeat_flutter/logic/chapter_help.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/logic/widget/copy_template.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/repeat/repeat_args.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'gs_cr_state.dart';

class GsCrLogic extends GetxController {
  static const String id = "GsCrLogic";
  static const String idForAdd = "GsCrLogicForAdd";
  final GsCrState state = GsCrState();
  late CopyLogic copyLogic = CopyLogic<GsCrLogic>(CrK.copyListTemplate, this);
  Timer? timer;

  @override
  void onInit() {
    super.onInit();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showTransparentOverlay(() async {
        await init();
      });
    });
  }

  @override
  void onClose() {
    super.onClose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
  }

  Future<void> init({TodayPrgType? type}) async {
    await copyLogic.init();
    await VerseHelp.tryGen(force: true);
    VerseDao.getVerseShow = VerseHelp.getCache;
    await ChapterHelp.tryGen(force: true);
    ChapterDao.getChapterShow = ChapterHelp.getCache;
    await BookHelp.tryGen(force: true);
    BookDao.getBookShow = BookHelp.getCache;
    state.forAdd.contents = await Db().db.bookDao.getByEnable(Classroom.curr, true);
    state.forAdd.contentNames = state.forAdd.contents.map((e) => e.name).toList();
    var now = DateTime.now();
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
    for (var index = 0; index < scheduleConfig.elConfigs.length; index++) {
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
      var config = scheduleConfig.elConfigs.elementAt(index);
      rule.index = index;
      rule.uniqIndex = uniqIndex++;
      rule.type = TodayPrgType.learn;
      rule.name = config.title == "" ? "R$index: $learnedTotalCount/$learnTotalCount" : "${config.title}: $learnedTotalCount/$learnTotalCount";
      rule.desc = config.tr();
      learn.add(rule);
      state.learn.addAll(rule.verses);
    }
    for (var index = 0; index < scheduleConfig.relConfigs.length; index++) {
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
      var config = scheduleConfig.relConfigs.elementAt(index);
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

    var todayLearnCreateDate = await Db().db.scheduleDao.intKv(Classroom.curr, CrK.todayScheduleCreateDate) ?? 0;
    var next = ScheduleDao.getNext(now, ScheduleDao.scheduleConfig.intervalSeconds);
    if (todayLearnCreateDate != 0 && next.value - todayLearnCreateDate > 0 && todayLearnCreateDate == Date.from(now).value) {
      state.learnDeadline = next.toDateTime().millisecondsSinceEpoch;
    }
    resetLearnDeadline();

    state.learnedTotalCount = VerseTodayPrg.getFinishedCount(allProgresses);
    state.learnTotalCount = allProgresses.length;

    for (var l in learn) {
      var learnedTotalCount = VerseTodayPrg.getFinishedCount(state.learn);
      var learnTotalCount = state.learn.length;
      l.groupDesc = toGroupName(TodayPrgType.learn) + ": $learnedTotalCount/$learnTotalCount";
    }

    for (var l in review) {
      var learnedTotalCount = VerseTodayPrg.getFinishedCount(state.review);
      var learnTotalCount = state.review.length;
      l.groupDesc = toGroupName(TodayPrgType.review) + ": $learnedTotalCount/$learnTotalCount";
    }

    for (var l in fullCustom) {
      var learnedTotalCount = VerseTodayPrg.getFinishedCount(state.fullCustom);
      var learnTotalCount = state.fullCustom.length;
      l.groupDesc = toGroupName(TodayPrgType.fullCustom) + ": $learnedTotalCount/$learnTotalCount";
    }

    state.all.sort((a, b) => a.sort.compareTo(b.sort));
    state.learn.sort((a, b) => a.sort.compareTo(b.sort));
    state.review.sort((a, b) => a.sort.compareTo(b.sort));
    state.fullCustom.sort((a, b) => a.sort.compareTo(b.sort));

    startTimer();
    update([GsCrLogic.id]);
  }

  tryStartAll({RepeatType mode = RepeatType.normal}) {
    tryStart(state.all, mode: mode);
  }

  tryStartGroup(TodayPrgType type, {RepeatType mode = RepeatType.normal}) {
    if (type == TodayPrgType.learn) {
      tryStart(state.learn, mode: mode);
    } else if (type == TodayPrgType.review) {
      tryStart(state.review, mode: mode);
    } else if (type == TodayPrgType.fullCustom) {
      tryStart(state.fullCustom, mode: mode);
    }
  }

  toGroupName(TodayPrgType type) {
    if (type == TodayPrgType.learn) {
      return I18nKey.btnLearn.tr;
    } else if (type == TodayPrgType.review) {
      return I18nKey.btnReview.tr;
    } else {
      return I18nKey.btnFullCustom.tr;
    }
  }

  void tryStart(List<VerseTodayPrg> list, {bool grouping = false, RepeatType mode = RepeatType.normal}) async {
    if (list.isEmpty) {
      Snackbar.show(I18nKey.labelNoLearningContent.tr);
      return;
    }
    if (grouping) {
      list = VerseTodayPrg.getFirstUnfinishedGroup(list);
    }
    if (mode == RepeatType.normal) {
      var learnedTotalCount = VerseTodayPrg.getFinishedCount(list);
      var learnTotalCount = list.length;
      if (learnTotalCount - learnedTotalCount == 0) {
        Snackbar.show(I18nKey.labelNoLearningContent.tr);
        return;
      }
    }
    var repeat = RepeatArgs(
      progresses: list,
      repeatType: mode,
      enableShowRecallButtons: true,
      defaultEdit: false,
    );
    await Nav.repeat.push(arguments: repeat);
    await init();
  }

  resetLearnDeadline() {
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

  void config(TodayPrgType type) async {
    if (type == TodayPrgType.fullCustom) {
      return;
    }
    showTransparentOverlay(() async {
      Nav.gsCrSettings.push();
      await Future.delayed(const Duration(milliseconds: 700));
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (type == TodayPrgType.learn) {
      Nav.gsCrSettingsEl.push();
    } else {
      Nav.gsCrSettingsRel.push();
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

  Future<bool> initForAdd() async {
    if (state.forAdd.contents.isEmpty) {
      Snackbar.show(I18nKey.labelNoContent.tr);
      return false;
    }
    await showTransparentOverlay(() async {
      state.forAdd.maxChapter = -1;
      state.forAdd.maxVerse = -1;
      state.forAdd.fromBook = state.forAdd.contents[0];
      await initChapter(updateView: false);
      await initVerse(updateView: false);
      state.forAdd.fromContentIndex = 0;
      state.forAdd.fromChapterIndex = 0;
      state.forAdd.fromVerseIndex = 0;
      state.forAdd.count = 1;
    });
    return true;
  }

  Future<void> initChapter({bool updateView = true}) async {
    if (state.forAdd.maxChapter < 0) {
      var bookId = state.forAdd.fromBook!.id!;
      var maxChapter = await Db().db.scheduleDao.getMaxChapterIndex(bookId);
      state.forAdd.maxChapter = (maxChapter ?? 1) + 1;
      if (updateView) {
        update([GsCrLogic.idForAdd]);
      }
    }
  }

  Future<void> initVerse({bool updateView = true}) async {
    if (state.forAdd.maxChapter < 0) {
      return;
    }
    if (state.forAdd.maxVerse < 0) {
      var bookId = state.forAdd.fromBook!.id!;
      var maxVerse = await Db().db.scheduleDao.getMaxVerseIndex(bookId, state.forAdd.fromChapterIndex);
      state.forAdd.maxVerse = (maxVerse ?? 1) + 1;
      if (updateView) {
        update([GsCrLogic.idForAdd]);
      }
    }
  }

  void selectContent(int contentIndex) async {
    var content = state.forAdd.contents[contentIndex];
    state.forAdd.maxChapter = -1;
    state.forAdd.maxVerse = -1;
    state.forAdd.fromBook = content;
    state.forAdd.fromContentIndex = contentIndex;
    state.forAdd.fromChapterIndex = 0;
    state.forAdd.fromVerseIndex = 0;

    update([GsCrLogic.idForAdd]);
  }

  void selectChapter(int chapterIndex) async {
    state.forAdd.maxVerse = -1;
    state.forAdd.fromChapterIndex = chapterIndex;
    state.forAdd.fromVerseIndex = 0;
    update([GsCrLogic.idForAdd]);
  }

  void selectVerse(int verseIndex) async {
    state.forAdd.fromVerseIndex = verseIndex;
  }

  void selectCount(int count) async {
    state.forAdd.count = count + 1;
  }

  void addSchedule() async {
    if (state.forAdd.maxChapter < 0) {
      return;
    }
    if (state.forAdd.maxVerse < 0) {
      return;
    }
    await Db().db.scheduleDao.addFullCustom(
          state.forAdd.fromBook!.id!,
          state.forAdd.fromChapterIndex,
          state.forAdd.fromVerseIndex,
          state.forAdd.count,
        );
    await init();
  }

  // for copy
  void copy(BuildContext context, List<VerseTodayPrg> verses) async {
    List<VerseShow> ret = [];
    for (int i = 0; i < verses.length; i++) {
      final verse = verses[i];
      VerseShow? verseShow = VerseHelp.getCache(verse.verseId);
      if (verseShow != null) {
        ret.add(verseShow);
      }
    }
    if (!copyLogic.showQaList(context, ret)) {
      Snackbar.show(I18nKey.labelNoContent.tr);
    }
  }
}
