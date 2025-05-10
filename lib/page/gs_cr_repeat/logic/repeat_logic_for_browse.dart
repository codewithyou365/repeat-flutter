import 'package:get/get.dart';
import 'package:repeat_flutter/common/await_util.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/segment_help.dart' show SegmentHelp;
import 'package:repeat_flutter/page/gs_cr_repeat/logic/repeat_logic.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'constant.dart';
import 'game_helper.dart';
import 'time_stats_logic.dart';

class RepeatLogicForBrowse extends RepeatLogic {
  TimeStatsLogic timeStatsLogic = TimeStatsLogic();
  late List<SegmentTodayPrg> scheduled;

  int index = 0;
  Ticker ticker = Ticker(1000);

  @override
  SegmentTodayPrg? get currSegment {
    if (index < scheduled.length) {
      return scheduled[index];
    }
    return null;
  }

  @override
  SegmentTodayPrg? get nextSegment {
    if (index + 1 < scheduled.length) {
      return scheduled[index + 1];
    }
    return null;
  }

  @override
  String get titleLabel {
    String pos = "";
    if (currSegment != null) {
      pos = SegmentHelp.getSegmentPos(currSegment!.segmentKeyId);
    }
    return '${index + 1}/${scheduled.length} $pos';
  }

  @override
  String get leftLabel {
    String nextDiffKey = "";
    if (currSegment!.sort + 1 != nextSegment?.sort) {
      if (nextSegment != null) {
        nextDiffKey = SegmentHelp.getSegmentPos(nextSegment!.segmentKeyId);
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
  Future<bool> init(List<SegmentTodayPrg> all, Function() update, GameHelper gameHelper) async {
    if (all.isEmpty) {
      Snackbar.show(I18nKey.labelNoLearningContent.tr);
      return false;
    }
    this.update = update;
    this.gameHelper = gameHelper;
    scheduled = all;

    await gameHelper.tryRefreshGame(currSegment!);
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
    if (currSegment == null) {
      return;
    }
    await Db().db.scheduleDao.jumpDirectly(currSegment!.segmentKeyId, progress, nextDayValue);
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
    await gameHelper.tryRefreshGame(currSegment!);
    await timeStatsLogic.updateTimeStats();
  }

  Future<void> prev() async {
    tip = TipLevel.none;
    step = RepeatStep.recall;
    if (index > 0) {
      index--;
    }
    await gameHelper.tryRefreshGame(currSegment!);
    await timeStatsLogic.updateTimeStats();
  }
}
