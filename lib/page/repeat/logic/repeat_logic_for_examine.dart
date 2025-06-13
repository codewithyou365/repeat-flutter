import 'package:get/get.dart';
import 'package:repeat_flutter/common/await_util.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/verse_help.dart' show VerseHelp;
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'constant.dart';
import 'game_helper.dart';
import 'repeat_logic.dart';
import 'time_stats_logic.dart';

class RepeatLogicForExamine extends RepeatLogic {
  TimeStatsLogic timeStatsLogic = TimeStatsLogic();
  late List<VerseTodayPrg> scheduled;

  int total = 0;
  Ticker ticker = Ticker(1000);

  @override
  VerseTodayPrg? get currVerse {
    if (scheduled.isNotEmpty) {
      return scheduled[0];
    } else {
      return null;
    }
  }

  @override
  VerseTodayPrg? get nextVerse {
    if (1 < scheduled.length) {
      return scheduled[1];
    }
    return null;
  }

  @override
  String get titleLabel {
    String pos = "";
    if (currVerse != null) {
      pos = VerseHelp.getVersePos(currVerse!.verseKeyId);
    }
    return '${total - scheduled.length}/$total $pos';
  }

  @override
  String get leftLabel {
    String nextDiffKey = "";
    if (currVerse != null && currVerse!.sort + 1 != nextVerse?.sort) {
      if (nextVerse != null) {
        nextDiffKey = VerseHelp.getVersePos(nextVerse!.verseKeyId);
      }
    }
    switch (step) {
      case RepeatStep.recall:
        return I18nKey.btnCheck.tr;
      case RepeatStep.evaluate:
        if (scheduled.length == 1) {
          if (currVerse!.progress + 1 == ScheduleDao.scheduleConfig.maxRepeatTime) {
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
  Future<bool> init(List<VerseTodayPrg> all, Function() update, GameHelper gameHelper) async {
    if (all.isEmpty) {
      Snackbar.show(I18nKey.labelNoLearningContent.tr);
      return false;
    }
    this.update = update;
    this.gameHelper = gameHelper;
    total = all.length;
    scheduled = VerseTodayPrg.refineWithFinish(all, false);
    scheduled.sort(schedulesCurrentSort);
    await gameHelper.tryRefreshGame(currVerse!);
    await timeStatsLogic.tryInsertTimeStats();
    return true;
  }

  @override
  onClose() {
    timeStatsLogic.updateTimeStats();
  }

  @override
  void onTapLeft() {
    AwaitUtil.tryDo(_onTapLeft);
  }

  Future<void> _onTapLeft() async {
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
    return () {
      AwaitUtil.tryDo(_getLongTapRight);
    };
  }

  Future<void> _getLongTapRight() async {
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
  }

  @override
  Future<void> jump({required int progress, required int nextDayValue}) async {
    if (currVerse == null) {
      return;
    }
    await Db().db.scheduleDao.jump(currVerse!, progress, nextDayValue);
    next();
  }

  void show() {
    step = RepeatStep.evaluate;
  }

  Future<void> right() async {
    step = RepeatStep.recall;
    await Db().db.scheduleDao.right(currVerse!);
    await next();
  }

  Future<void> next() async {
    if (currVerse!.progress >= ScheduleDao.scheduleConfig.maxRepeatTime) {
      scheduled.removeAt(0);
    }
    tip = TipLevel.none;
    scheduled.sort(schedulesCurrentSort);
    await gameHelper.tryRefreshGame(currVerse!);
    await timeStatsLogic.updateTimeStats();
  }

  Future<void> error() async {
    step = RepeatStep.recall;
    tip = TipLevel.none;
    await Db().db.scheduleDao.error(currVerse!);
    scheduled.sort(schedulesCurrentSort);
    await gameHelper.tryRefreshGame(currVerse!);
  }

  int schedulesCurrentSort(VerseTodayPrg a, VerseTodayPrg b) {
    if (a.viewTime != b.viewTime) {
      return a.viewTime.compareTo(b.viewTime);
    } else {
      return a.sort.compareTo(b.sort);
    }
  }
}
