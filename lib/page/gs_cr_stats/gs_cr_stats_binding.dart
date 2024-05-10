import 'package:get/get.dart';

import 'gs_cr_stats_logic.dart';

class GsCrStatsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsCrStatsLogic());
  }
}
