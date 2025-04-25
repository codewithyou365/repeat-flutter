import 'package:get/get.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/segment_help.dart' show SegmentHelp;
import 'package:repeat_flutter/page/gs_cr_repeat/logic/repeat_logic.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'constant.dart';
import 'time_stats_logic.dart';

class RepeatLogicForExamine extends RepeatLogic {
  TimeStatsLogic timeStatsLogic = TimeStatsLogic();
  late List<SegmentTodayPrg> scheduled;

  int total = 0;
  Ticker ticker = Ticker(1000);

  @override
  SegmentTodayPrg? get currSegment {
    if (scheduled.isNotEmpty) {
      return scheduled[0];
    } else {
      return null;
    }
  }

  @override
  SegmentTodayPrg? get nextSegment {
    if (1 < scheduled.length) {
      return scheduled[1];
    }
    return null;
  }

  @override
  String get titleLabel {
    String pos = "";
    if (currSegment != null) {
      pos = SegmentHelp.getSegmentPos(currSegment!.segmentKeyId);
    }
    return '${total - scheduled.length}/$total $pos';
  }

  @override
  String get leftLabel {
    String nextDiffKey = "";
    if (currSegment != null && currSegment!.sort + 1 != nextSegment?.sort) {
      if (nextSegment != null) {
        nextDiffKey = SegmentHelp.getSegmentPos(nextSegment!.segmentKeyId);
      }
    }
    switch (step) {
      case RepeatStep.recall:
        return I18nKey.btnCheck.tr;
      case RepeatStep.evaluate:
        if (scheduled.length == 1) {
          if (currSegment!.progress + 1 == ScheduleDao.scheduleConfig.maxRepeatTime) {
            return I18nKey.btnFinish.tr;
          }
          return I18nKey.btnNext.tr;
        } else if (nextDiffKey == "") {
          return I18nKey.btnNext.tr;
        } else {
          return "${I18nKey.btnNext.tr}\n$nextDiffKey";
        }
      default:
        return "";
    }
  }

  @override
  String get rightLabel {
    switch (step) {
      case RepeatStep.recall:
        return I18nKey.btnUnknown.tr;
      case RepeatStep.evaluate:
        return I18nKey.btnError.tr;
      default:
        return I18nKey.btnError.tr;
    }
  }

  @override
  Future<bool> init(List<SegmentTodayPrg> all, Function() update) async {
    if (all.isEmpty) {
      Snackbar.show(I18nKey.labelNoLearningContent.tr);
      return false;
    }
    this.update = update;
    total = all.length;
    scheduled = SegmentTodayPrg.refineWithFinish(all, false);
    scheduled.sort(schedulesCurrentSort);
    await timeStatsLogic.tryInsertTimeStats();
    return true;
  }

  @override
  onClose() {
    timeStatsLogic.updateTimeStats();
  }

  @override
  void onTapLeft() async {
    if (ticker.isStuck()) {
      return;
    }
    switch (step) {
      case RepeatStep.recall:
        show();
        break;
      case RepeatStep.evaluate:
        await right();
        if (scheduled.isEmpty) {
          Get.back();
        }
        break;
      default:
        break;
    }
    update();
  }

  @override
  void onTapMiddle() {
    tip = TipLevel.tip;
    update();
  }

  @override
  void onTapRight() async {
    Snackbar.show(I18nKey.labelOnTapError.tr);
  }

  @override
  Function()? getLongTapRight() {
    return () async {
      if (ticker.isStuck()) {
        return;
      }
      switch (step) {
        case RepeatStep.recall:
          await error();
          break;
        case RepeatStep.evaluate:
          await error();
          break;
        default:
          break;
      }
      update();
    };
  }

  @override
  Future<void> jump({required int progress, required int nextDayValue}) async {
    if (currSegment == null) {
      return;
    }
    await Db().db.scheduleDao.jump(currSegment!, progress, nextDayValue);
    next();
  }

  void show() {
    step = RepeatStep.evaluate;
  }

  Future<void> right() async {
    step = RepeatStep.recall;
    await Db().db.scheduleDao.right(currSegment!);
    next();
  }

  void next() {
    if (currSegment!.progress >= ScheduleDao.scheduleConfig.maxRepeatTime) {
      scheduled.removeAt(0);
    }
    tip = TipLevel.none;
    scheduled.sort(schedulesCurrentSort);
    timeStatsLogic.updateTimeStats();
  }

  Future<void> error() async {
    step = RepeatStep.recall;
    tip = TipLevel.none;
    await Db().db.scheduleDao.error(currSegment!);
    scheduled.sort(schedulesCurrentSort);
  }

  int schedulesCurrentSort(SegmentTodayPrg a, SegmentTodayPrg b) {
    if (a.viewTime != b.viewTime) {
      return a.viewTime.compareTo(b.viewTime);
    } else {
      return a.sort.compareTo(b.sort);
    }
  }
}
