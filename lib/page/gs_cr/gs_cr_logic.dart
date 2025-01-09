import 'dart:async';

import 'dart:convert' as convert;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/repeat_doc_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'gs_cr_state.dart';

class GsCrLogic extends GetxController {
  static const String id = "GsCrLogic";
  static const String idForAdd = "GsCrLogicForAdd";
  final GsCrState state = GsCrState();
  List<SegmentTodayPrg> currProgresses = [];
  Timer? timer;

  @override
  void onInit() {
    super.onInit();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    RepeatDocHelp.clear();
    init();
  }

  @override
  void onClose() {
    super.onClose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
  }

  Future<void> init({TodayPrgType? type}) async {
    state.forAdd.contents = await Db().db.contentDao.getAllEnableContent(Classroom.curr);
    state.forAdd.contentNames = state.forAdd.contents.map((e) => e.name).toList();
    var now = DateTime.now();
    List<SegmentTodayPrg> allProgresses = [];
    if (type == null) {
      allProgresses = await Db().db.scheduleDao.initToday();
    } else {
      allProgresses = await Db().db.scheduleDao.forceInitToday(type);
    }

    state.all = allProgresses;
    state.fullCustom = [];
    state.review = [];
    state.learn = [];
    state.segments = [];
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
    List<SegmentTodayPrgInView> learn = [];
    List<SegmentTodayPrgInView> review = [];
    List<SegmentTodayPrgInView> fullCustom = [];
    Map<int, SegmentTodayPrgInView> typeToSegment = {};
    for (var item in allProgresses) {
      var prgTypeAndIndex = SegmentTodayPrg.getPrgTypeAndIndex(item.type);

      SegmentTodayPrgInView view;
      if (typeToSegment.containsKey(prgTypeAndIndex)) {
        view = typeToSegment[prgTypeAndIndex]!;
      } else {
        view = SegmentTodayPrgInView([]);
        typeToSegment[prgTypeAndIndex] = view;
      }
      view.segments.add(item);
    }
    int uniqIndex = 0;
    for (var index = 0; index < scheduleConfig.elConfigs.length; index++) {
      var prgTypeAndIndex = SegmentTodayPrg.toPrgTypeAndIndex(TodayPrgType.learn, index);
      var learnedTotalCount = 0;
      var learnTotalCount = 0;
      SegmentTodayPrgInView rule;
      if (typeToSegment.containsKey(prgTypeAndIndex)) {
        rule = typeToSegment[prgTypeAndIndex]!;
        learnedTotalCount = SegmentTodayPrg.getFinishedCount(rule.segments);
        learnTotalCount = rule.segments.length;
      } else {
        rule = SegmentTodayPrgInView([]);
      }
      var config = scheduleConfig.elConfigs.elementAt(index);
      rule.index = index;
      rule.uniqIndex = uniqIndex++;
      rule.type = TodayPrgType.learn;
      rule.name = config.title == "" ? "R$index: $learnedTotalCount/$learnTotalCount" : "${config.title}: $learnedTotalCount/$learnTotalCount";
      rule.desc = config.tr();
      learn.add(rule);
      state.learn.addAll(rule.segments);
    }
    for (var index = 0; index < scheduleConfig.relConfigs.length; index++) {
      var prgTypeAndIndex = SegmentTodayPrg.toPrgTypeAndIndex(TodayPrgType.review, index);
      var learnedTotalCount = 0;
      var learnTotalCount = 0;
      SegmentTodayPrgInView rule;
      if (typeToSegment.containsKey(prgTypeAndIndex)) {
        rule = typeToSegment[prgTypeAndIndex]!;
        learnedTotalCount = SegmentTodayPrg.getFinishedCount(rule.segments);
        learnTotalCount = rule.segments.length;
      } else {
        rule = SegmentTodayPrgInView([]);
      }
      var config = scheduleConfig.relConfigs.elementAt(index);
      rule.index = index;
      rule.uniqIndex = uniqIndex++;
      rule.type = TodayPrgType.review;
      rule.name = config.title == "" ? "R$index: $learnedTotalCount/$learnTotalCount" : "${config.title}: $learnedTotalCount/$learnTotalCount";
      rule.desc = config.tr();
      review.add(rule);
      state.review.addAll(rule.segments);
    }
    for (var index = 0; index < fullCustomConfigs.length; index++) {
      var prgTypeAndIndex = SegmentTodayPrg.toPrgTypeAndIndex(TodayPrgType.fullCustom, index);
      var learnedTotalCount = 0;
      var learnTotalCount = 0;
      SegmentTodayPrgInView rule;
      if (typeToSegment.containsKey(prgTypeAndIndex)) {
        rule = typeToSegment[prgTypeAndIndex]!;
        learnedTotalCount = SegmentTodayPrg.getFinishedCount(rule.segments);
        learnTotalCount = rule.segments.length;
      } else {
        rule = SegmentTodayPrgInView([]);
      }
      rule.index = index;
      rule.uniqIndex = uniqIndex++;
      rule.type = TodayPrgType.fullCustom;
      rule.name = "$index: $learnedTotalCount/$learnTotalCount";
      rule.desc = I18nKey.labelFullCustomConfig.trParams(fullCustomConfigs[index]);
      fullCustom.add(rule);
      state.fullCustom.addAll(rule.segments);
    }
    state.segments.addAll(learn);
    state.segments.addAll(review);
    state.segments.addAll(fullCustom);

    var todayLearnCreateDate = await Db().db.scheduleDao.intKv(Classroom.curr, CrK.todayScheduleCreateDate) ?? 0;
    var next = Db().db.scheduleDao.getNext(now, ScheduleDao.scheduleConfig.intervalSeconds);
    if (todayLearnCreateDate != 0 && next.value - todayLearnCreateDate > 0 && todayLearnCreateDate == Date.from(now).value) {
      state.learnDeadline = next.toDateTime().millisecondsSinceEpoch;
    }
    resetLearnDeadline();

    state.learnedTotalCount = SegmentTodayPrg.getFinishedCount(allProgresses);
    state.learnTotalCount = allProgresses.length;

    for (var l in learn) {
      var learnedTotalCount = SegmentTodayPrg.getFinishedCount(state.learn);
      var learnTotalCount = state.learn.length;
      l.groupDesc = toGroupName(TodayPrgType.learn) + ": $learnedTotalCount/$learnTotalCount";
    }

    for (var l in review) {
      var learnedTotalCount = SegmentTodayPrg.getFinishedCount(state.review);
      var learnTotalCount = state.review.length;
      l.groupDesc = toGroupName(TodayPrgType.review) + ": $learnedTotalCount/$learnTotalCount";
    }

    for (var l in fullCustom) {
      var learnedTotalCount = SegmentTodayPrg.getFinishedCount(state.fullCustom);
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

  tryStartAll({Repeat mode = Repeat.normal}) {
    tryStart(state.all, mode: mode);
  }

  tryStartGroup(TodayPrgType type, {Repeat mode = Repeat.normal}) {
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

  tryStart(List<SegmentTodayPrg> list, {bool grouping = false, Repeat mode = Repeat.normal}) {
    if (list.isEmpty) {
      Snackbar.show(I18nKey.labelNoLearningContent.tr);
      return;
    }
    if (grouping) {
      list = SegmentTodayPrg.getFirstUnfinishedGroup(list);
    }
    if (mode == Repeat.normal) {
      var learnedTotalCount = SegmentTodayPrg.getFinishedCount(list);
      var learnTotalCount = list.length;
      if (learnTotalCount - learnedTotalCount == 0) {
        Snackbar.show(I18nKey.labelNoLearningContent.tr);
        return;
      }
    }
    currProgresses = list;
    Nav.gsCrRepeat.push(arguments: mode);
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
    MsgBox.yesOrNo(I18nKey.labelReset.tr, desc, yes: () {
      showOverlay(() async {
        await init(type: type);
        Nav.back();
        Snackbar.show(I18nKey.labelFinish.tr);
      }, I18nKey.labelExecuting.tr);
    });
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
      state.forAdd.maxLesson = -1;
      state.forAdd.maxSegment = -1;
      state.forAdd.fromContent = state.forAdd.contents[0];
      await initLesson(updateView: false);
      await initSegment(updateView: false);
      state.forAdd.fromContentIndex = 0;
      state.forAdd.fromLessonIndex = 0;
      state.forAdd.fromSegmentIndex = 0;
      state.forAdd.count = 1;
    });
    return true;
  }

  Future<void> initLesson({bool updateView = true}) async {
    if (state.forAdd.maxLesson < 0) {
      var contentSerial = state.forAdd.fromContent!.serial;
      var maxLesson = await Db().db.scheduleDao.getMaxLessonIndex(Classroom.curr, contentSerial);
      state.forAdd.maxLesson = (maxLesson ?? 1) + 1;
      if (updateView) {
        update([GsCrLogic.idForAdd]);
      }
    }
  }

  Future<void> initSegment({bool updateView = true}) async {
    if (state.forAdd.maxLesson < 0) {
      return;
    }
    if (state.forAdd.maxSegment < 0) {
      var contentSerial = state.forAdd.fromContent!.serial;
      var maxSegment = await Db().db.scheduleDao.getMaxSegmentIndex(Classroom.curr, contentSerial, state.forAdd.fromLessonIndex);
      state.forAdd.maxSegment = (maxSegment ?? 1) + 1;
      if (updateView) {
        update([GsCrLogic.idForAdd]);
      }
    }
  }

  void selectContent(int contentIndex) async {
    var content = state.forAdd.contents[contentIndex];
    state.forAdd.maxLesson = -1;
    state.forAdd.maxSegment = -1;
    state.forAdd.fromContent = content;
    state.forAdd.fromContentIndex = contentIndex;
    state.forAdd.fromLessonIndex = 0;
    state.forAdd.fromSegmentIndex = 0;

    update([GsCrLogic.idForAdd]);
  }

  void selectLesson(int lessonIndex) async {
    state.forAdd.maxSegment = -1;
    state.forAdd.fromLessonIndex = lessonIndex;
    state.forAdd.fromSegmentIndex = 0;
    update([GsCrLogic.idForAdd]);
  }

  void selectSegment(int segmentIndex) async {
    state.forAdd.fromSegmentIndex = segmentIndex;
  }

  void selectCount(int count) async {
    state.forAdd.count = count + 1;
  }

  void addSchedule() async {
    if (state.forAdd.maxLesson < 0) {
      return;
    }
    if (state.forAdd.maxSegment < 0) {
      return;
    }
    await Db().db.scheduleDao.addFullCustom(
          state.forAdd.fromContent!.serial,
          state.forAdd.fromLessonIndex,
          state.forAdd.fromSegmentIndex,
          state.forAdd.count,
        );
    await init();
  }
}
