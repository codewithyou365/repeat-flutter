import 'package:get/get.dart';

import 'sc_cr_stats_trend_logic.dart';

class ScCrStatsTrendBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScCrStatsTrendLogic());
  }
}
