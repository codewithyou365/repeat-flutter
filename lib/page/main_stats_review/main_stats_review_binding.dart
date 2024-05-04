import 'package:get/get.dart';

import 'main_stats_review_logic.dart';

class MainStatsReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MainStatsReviewLogic());
  }
}
