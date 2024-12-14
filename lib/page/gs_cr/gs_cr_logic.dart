import 'dart:async';

import 'dart:convert' as convert;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content.dart';
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
    state.forAdd.contents = await Db().db.contentDao.getAllContent(Classroom.curr);
    state.forAdd.contentNames = state.forAdd.contents.map((e) => e.name).toList();
    selectContent(0);
    var now = DateTime.now();
    List<SegmentTodayPrg> allProgresses = [];
    if (type == null) {
      allProgresses = await Db().db.scheduleDao.initToday();
    } else {
      allProgresses = await Db().db.scheduleDao.forceInitToday(type);
    }

    state.all = allProgresses;
    state.review = [];
    state.learn = [];
    state.segments = [];

    var configInUseJsonStr = await Db().db.scheduleDao.stringKv(Classroom.curr, CrK.todayLearnScheduleConfigInUse);
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
    Map<int, SegmentTodayPrgInView> temp = {};
    for (var item in allProgresses) {
      var prgTypeAndIndex = SegmentTodayPrg.getPrgTypeAndIndex(item.type);

      SegmentTodayPrgInView view;
      if (temp.containsKey(prgTypeAndIndex)) {
        view = temp[prgTypeAndIndex]!;
      } else {
        view = SegmentTodayPrgInView([]);
        temp[prgTypeAndIndex] = view;
      }
      view.segments.add(item);
    }
    int uniqIndex = 0;
    for (var index = 0; index < scheduleConfig.elConfigs.length; index++) {
      var prgTypeAndIndex = SegmentTodayPrg.toPrgTypeAndIndex(TodayPrgType.learn, index);
      var learnedTotalCount = 0;
      var learnTotalCount = 0;
      SegmentTodayPrgInView rule;
      if (temp.containsKey(prgTypeAndIndex)) {
        rule = temp[prgTypeAndIndex]!;
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
      if (temp.containsKey(prgTypeAndIndex)) {
        rule = temp[prgTypeAndIndex]!;
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
    state.segments.addAll(learn);
    state.segments.addAll(review);

    var todayLearnCreateDate = await Db().db.scheduleDao.intKv(Classroom.curr, CrK.todayLearnCreateDate) ?? 0;
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

    state.all.sort((a, b) => a.sort.compareTo(b.sort));
    state.learn.sort((a, b) => a.sort.compareTo(b.sort));
    state.review.sort((a, b) => a.sort.compareTo(b.sort));

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
    }
  }

  toGroupName(TodayPrgType type) {
    if (type == TodayPrgType.learn) {
      return I18nKey.btnLearn.tr;
    } else {
      return I18nKey.btnReview.tr;
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
    var desc = type == TodayPrgType.learn ? I18nKey.labelResetLearnDesc.tr : I18nKey.labelResetReviewDesc.tr;
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
      await Db().db.scheduleDao.deleteKv(CrKv(Classroom.curr, CrK.todayLearnCreateDate, ""));
      await init();
      Nav.back();
      Snackbar.show(I18nKey.labelFinish.tr);
    }, I18nKey.labelExecuting.tr);
  }

  void selectContent(int contentIndex) async {
    var content = state.forAdd.contents[contentIndex];
    var contentSerial = content.serial;
    var maxLesson = await Db().db.scheduleDao.getMaxLessonIndex(Classroom.curr, contentSerial);
    state.forAdd.maxLesson = (maxLesson ?? 1) + 1;
    var maxSegment = await Db().db.scheduleDao.getMaxSegmentIndex(Classroom.curr, contentSerial, 0);
    state.forAdd.maxSegment = (maxSegment ?? 1) + 1;
    state.forAdd.fromContent = content;
    state.forAdd.fromContentIndex = contentIndex;
    state.forAdd.fromLessonIndex = 0;
    state.forAdd.fromSegmentIndex = 0;
    update([GsCrLogic.idForAdd]);
  }

  void selectLesson(int lessonIndex) async {
    var contentSerial = state.forAdd.fromContent!.serial;
    var maxSegment = await Db().db.scheduleDao.getMaxSegmentIndex(Classroom.curr, contentSerial, lessonIndex);
    state.forAdd.maxSegment = (maxSegment ?? 1) + 1;

    state.forAdd.fromLessonIndex = lessonIndex;
    state.forAdd.fromSegmentIndex = 0;
    update([GsCrLogic.idForAdd]);
  }

  void selectSegment(int segmentIndex) async {
    state.forAdd.fromSegmentIndex = segmentIndex;
    update([GsCrLogic.idForAdd]);
  }

  void selectSegment1(int segmentIndex) async {
    state.forAdd.fromSegmentIndex = segmentIndex;
  }

  void shou() {
    showOverlay(() async {
      await Db().db.scheduleDao.deleteKv(CrKv(Classroom.curr, CrK.todayLearnCreateDate, ""));
      await init();
      Nav.back();
      Snackbar.show(I18nKey.labelFinish.tr);
    }, I18nKey.labelExecuting.tr);
  }
}
