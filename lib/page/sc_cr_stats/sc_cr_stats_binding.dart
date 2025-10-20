import 'package:get/get.dart';

import 'sc_cr_stats_logic.dart';

class ScCrStatsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScCrStatsLogic());
  }
}
