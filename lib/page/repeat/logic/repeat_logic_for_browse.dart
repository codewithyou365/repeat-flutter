import 'package:get/get.dart';
import 'package:repeat_flutter/common/await_util.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/verse_help.dart' show VerseHelp;
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'constant.dart';
import 'game_helper.dart';
import 'repeat_logic.dart';
import 'time_stats_logic.dart';

class RepeatLogicForBrowse extends RepeatLogic {
  TimeStatsLogic timeStatsLogic = TimeStatsLogic();
  late List<VerseTodayPrg> scheduled;

  int index = 0;
  Ticker ticker = Ticker(1000);

  @override
  VerseTodayPrg? get currVerse {
    if (index < scheduled.length) {
      return scheduled[index];
    }
    return null;
  }

  @override
  VerseTodayPrg? get nextVerse {
    if (index + 1 < scheduled.length) {
      return scheduled[index + 1];
    }
    return null;
  }

  @override
  String get titleLabel {
    String pos = "";
    if (currVerse != null) {
      pos = VerseHelp.getVersePos(currVerse!.verseKeyId);
    }
    return '${index + 1}/${scheduled.length} $pos';
  }

  @override
  String get leftLabel {
    String nextDiffKey = "";
    if (currVerse!.sort + 1 != nextVerse?.sort) {
      if (nextVerse != null) {
        nextDiffKey = VerseHelp.getVersePos(nextVerse!.verseKeyId);
      }
    }
    switch (step) {
      case RepeatStep.recall:
        return I18nKey.btnShow.tr;
      case RepeatStep.evaluate:
        if (nextDiffKey == "") {
          return I18nKey.btnNext.tr;
        } else {
          return "${I18nKey.btnNext.tr}\n$nextDiffKey";
        }
      case RepeatStep.finish:
        return I18nKey.btnFinish.tr;
    }
  }

  @override
  String get rightLabel {
    return I18nKey.btnPrevious.tr;
  }

  @override
  Future<bool> init(List<VerseTodayPrg> all, Function() update, GameHelper gameHelper) async {
    if (all.isEmpty) {
      Snackbar.show(I18nKey.labelNoLearningContent.tr);
      return false;
    }
    this.update = update;
    this.gameHelper = gameHelper;
    scheduled = all;

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
    if (ticker.isStuck()) {
      return;
    }
    switch (step) {
      case RepeatStep.recall:
        show();
        break;
      case RepeatStep.evaluate:
        if (!AwaitUtil.tryDo(next)) {
          return;
        }
        break;
      case RepeatStep.finish:
        Get.back();
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
  void onTapRight() {
    if (ticker.isStuck()) {
      return;
    }
    if (!AwaitUtil.tryDo(prev)) {
      return;
    }
    update();
  }

  @override
  Future<void> jump({required int progress, required int nextDayValue}) async {
    if (currVerse == null) {
      return;
    }
    await Db().db.scheduleDao.jumpDirectly(currVerse!.verseKeyId, progress, nextDayValue);
    await next();
  }

  void show() {
    if (index == scheduled.length - 1) {
      step = RepeatStep.finish;
    } else {
      step = RepeatStep.evaluate;
    }
  }

  Future<void> next() async {
    tip = TipLevel.none;
    step = RepeatStep.recall;
    if (index < scheduled.length - 1) {
      index++;
    }
    await gameHelper.tryRefreshGame(currVerse!);
    await timeStatsLogic.updateTimeStats();
  }

  Future<void> prev() async {
    tip = TipLevel.none;
    step = RepeatStep.recall;
    if (index > 0) {
      index--;
    }
    await gameHelper.tryRefreshGame(currVerse!);
    await timeStatsLogic.updateTimeStats();
  }
}
