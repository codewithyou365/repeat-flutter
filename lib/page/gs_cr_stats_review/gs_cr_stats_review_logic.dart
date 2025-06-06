import 'dart:math';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/logic/model/verse_review_with_key.dart';
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
    Date monthStart = Date.from(DateTime(focusedDay.year, focusedDay.month - 1, 1));
    Date monthEnd = Date.from(DateTime(focusedDay.year, focusedDay.month + 2, 1));

    state.learnCount = {};
    state.reviewCount = {};
    state.minCount = {};
    List<VerseReviewWithKey> review = await Db().db.scheduleDao.getAllVerseReview(Classroom.curr, monthStart, monthEnd);
    for (var e in review) {
      state.learnCount.update(e.createDate.value, (count) => count + 1, ifAbsent: () => 1);
      state.reviewCount.update(e.createDate.value, (count) => count + e.count, ifAbsent: () => e.count);
      state.minCount.update(e.createDate.value, (minVal) => min(minVal, e.count), ifAbsent: () => e.count);
    }
    state.focusedDay = focusedDay;
    update([id]);
  }
}
