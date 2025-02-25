import 'dart:math';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/segment_stats.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';

import 'gs_cr_stats_detail_state.dart';

class GsCrStatsDetailLogic extends GetxController {
  static const String id = "MainStatsDetailStateList";
  final GsCrStatsDetailState state = GsCrStatsDetailState();

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
    List<SegmentStats> data = await Db().db.statsDao.getStatsByDateRange(Classroom.curr, monthStart, monthEnd);
    for (var e in data) {
      if (e.type == TodayPrgType.learn.index) {
        state.learnCount.update(e.createDate.value, (count) => count + 1, ifAbsent: () => 1);
      } else if (e.type == TodayPrgType.review.index) {
        state.reviewCount.update(e.createDate.value, (count) => count + 1, ifAbsent: () => 1);
      } else if (e.type == TodayPrgType.fullCustom.index) {
        state.fullCustomCount.update(e.createDate.value, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    state.focusedDay = focusedDay;
    update([id]);
  }
}
