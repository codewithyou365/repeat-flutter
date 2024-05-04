import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/page/main_stats_review/main_stats_review_state.dart';

class MainStatsReviewLogic extends GetxController {
  static const String id = "MainStatsReviewStateList";
  final MainStatsReviewState state = MainStatsReviewState();

  @override
  onInit() async {
    super.onInit();
    state.progress = await Db().db.scheduleDao.getAllSegmentReview();
    update([id]);
  }
}
