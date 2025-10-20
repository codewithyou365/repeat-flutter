import 'package:get/get.dart';

import 'sc_cr_stats_detail_logic.dart';


class ScCrStatsDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScCrStatsDetailLogic());
  }
}
