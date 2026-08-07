import 'dart:math';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/logic/model/verse_stats_count.dart';

import 'sc_cr_stats_detail_state.dart';

class ScCrStatsDetailLogic extends GetxController {
  static const String id = "MainStatsDetailStateList";
  final ScCrStatsDetailState state = ScCrStatsDetailState();

  @override
  onInit() async {
    super.onInit();
    await onPageChanged(state.focusedDay);
  }

  Future<void> onPageChanged(DateTime focusedDay) async {
    state.learnCount = {};
    state.reviewCount = {};
    state.fullCustomCount = {};
    Date monthStart = Date.from(DateTime(focusedDay.year, focusedDay.month - 1, 1));
    Date monthEnd = Date.from(DateTime(focusedDay.year, focusedDay.month + 2, 1));
    List<VerseStatsCount> data = await Db().db.statsDao.getStatsCountByDateRange(Classroom.curr, monthStart, monthEnd);
    for (var e in data) {
      if (e.type == TodayPrgType.learn.index) {
        state.learnCount[e.createDate.value] = e.cnt;
      } else if (e.type == TodayPrgType.review.index) {
        state.reviewCount[e.createDate.value] = e.cnt;
      } else if (e.type == TodayPrgType.fullCustom.index) {
        state.fullCustomCount[e.createDate.value] = e.cnt;
      }
    }

    state.focusedDay = focusedDay;
    update([id]);
  }
}
