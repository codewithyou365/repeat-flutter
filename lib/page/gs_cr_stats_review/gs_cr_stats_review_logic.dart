import 'dart:math';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/logic/model/segment_review_with_key.dart';
import 'gs_cr_stats_review_state.dart';

class GsCrStatsReviewLogic extends GetxController {
  static const String id = "MainStatsReviewStateList";
  final GsCrStatsReviewState state = GsCrStatsReviewState();

  @override
  onInit() async {
    super.onInit();
    await onPageChanged(state.focusedDay);
  }

  Future<void> onPageChanged(DateTime focusedDay) async {
    state.number = {};
    state.minCount = {};
    Date monthStart = Date.from(DateTime(focusedDay.year, focusedDay.month - 1, 1));
    Date monthEnd = Date.from(DateTime(focusedDay.year, focusedDay.month + 2, 1));
    List<SegmentReviewWithKey> data = await Db().db.scheduleDao.getAllSegmentReview(Classroom.curr, monthStart, monthEnd);
    for (var e in data) {
      state.number.update(e.createDate.value, (count) => count + 1, ifAbsent: () => 1);
      state.minCount.update(e.createDate.value, (minVal) => min(minVal, e.count), ifAbsent: () => e.count);
    }
    state.focusedDay = focusedDay;
    update([id]);
  }
}
