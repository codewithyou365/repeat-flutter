import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'gs_cr_stats_review_state.dart';

class GsCrStatsReviewLogic extends GetxController {
  static const String id = "MainStatsReviewStateList";
  final GsCrStatsReviewState state = GsCrStatsReviewState();

  @override
  onInit() async {
    super.onInit();
    state.progress = await Db().db.scheduleDao.getAllSegmentReview();
    update([id]);
  }
}
