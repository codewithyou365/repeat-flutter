import 'package:get/get.dart';

import 'main_stats_logic.dart';

class MainStatsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MainStatsLogic());
  }
}
