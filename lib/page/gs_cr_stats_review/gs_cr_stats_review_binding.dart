import 'package:get/get.dart';

import 'gs_cr_stats_review_logic.dart';

class GsCrStatsReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsCrStatsReviewLogic());
  }
}
