import 'package:get/get.dart';

import 'main_stats_learn_logic.dart';

class MainStatsLearnBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MainStatsLearnLogic());
  }
}
