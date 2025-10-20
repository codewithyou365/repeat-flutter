import 'package:get/get.dart';

import 'sc_cr_stats_review_logic.dart';

class ScCrStatsReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScCrStatsReviewLogic());
  }
}
