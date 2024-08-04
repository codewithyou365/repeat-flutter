import 'dart:async';

import 'dart:convert' as convert;
import 'package:get/get.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/logic/constant.dart';
import 'package:repeat_flutter/logic/model/segment_today_prg_with_key.dart';
import 'package:repeat_flutter/logic/segment_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'gs_cr_state.dart';

class GsCrLogic extends GetxController {
  static const String id = "GsCrLogic";
  final GsCrState state = GsCrState();
  List<SegmentTodayPrgWithKey> currProgresses = [];
  Timer? timer;

  @override
  void onInit() {
    super.onInit();
    SegmentHelp.clear();
    init();
  }

  Future<void> init() async {
    var now = DateTime.now();
    List<SegmentTodayPrgWithKey> allProgresses = await Db().db.scheduleDao.initToday();
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
    List<SegmentTodayPrgWithKeyInView> learn = [];
    List<SegmentTodayPrgWithKeyInView> review = [];
    Map<int, SegmentTodayPrgWithKeyInView> temp = {};
    for (var item in allProgresses) {
      var prgTypeAndIndex = SegmentTodayPrg.getPrgTypeAndIndex(item.type);

      SegmentTodayPrgWithKeyInView view;
      if (temp.containsKey(prgTypeAndIndex)) {
        view = temp[prgTypeAndIndex]!;
      } else {
        view = SegmentTodayPrgWithKeyInView([]);
        temp[prgTypeAndIndex] = view;
      }
      view.segments.add(item);
    }
    int uniqIndex = 0;
    for (var index = 0; index < scheduleConfig.elConfigs.length; index++) {
      var prgTypeAndIndex = SegmentTodayPrg.toPrgTypeAndIndex(TodayPrgType.learn, index);
      var learnedTotalCount = 0;
      var learnTotalCount = 0;
      SegmentTodayPrgWithKeyInView rule;
      if (temp.containsKey(prgTypeAndIndex)) {
        rule = temp[prgTypeAndIndex]!;
        learnedTotalCount = SegmentTodayPrg.getFinishedCount(rule.segments);
        learnTotalCount = rule.segments.length;
      } else {
        rule = SegmentTodayPrgWithKeyInView([]);
      }
      rule.index = index;
      rule.uniqIndex = uniqIndex++;
      rule.type = TodayPrgType.learn;
      rule.name = "R$index: $learnedTotalCount/$learnTotalCount";
      rule.desc = scheduleConfig.elConfigs.elementAt(index).tr();
      learn.add(rule);
      state.learn.addAll(rule.segments);
    }
    for (var index = 0; index < scheduleConfig.relConfigs.length; index++) {
      var prgTypeAndIndex = SegmentTodayPrg.toPrgTypeAndIndex(TodayPrgType.review, index);
      var learnedTotalCount = 0;
      var learnTotalCount = 0;
      SegmentTodayPrgWithKeyInView rule;
      if (temp.containsKey(prgTypeAndIndex)) {
        rule = temp[prgTypeAndIndex]!;
        learnedTotalCount = SegmentTodayPrg.getFinishedCount(rule.segments);
        learnTotalCount = rule.segments.length;
      } else {
        rule = SegmentTodayPrgWithKeyInView([]);
      }
      rule.index = index;
      rule.uniqIndex = uniqIndex++;
      rule.type = TodayPrgType.review;
      rule.name = "R$index: $learnedTotalCount/$learnTotalCount";
      rule.desc = scheduleConfig.relConfigs.elementAt(index).tr();
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

  tryStart(List<SegmentTodayPrgWithKey> list, {bool grouping = false, Repeat mode = Repeat.normal}) {
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
}
