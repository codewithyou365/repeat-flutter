import 'package:get/get.dart';

import 'gs_cr_stats_learn_logic.dart';

class GsCrStatsLearnBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsCrStatsLearnLogic());
  }
}
