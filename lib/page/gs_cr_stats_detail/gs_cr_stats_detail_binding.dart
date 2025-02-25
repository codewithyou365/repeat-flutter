import 'package:get/get.dart';

import 'gs_cr_stats_detail_logic.dart';


class GsCrStatsDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsCrStatsDetailLogic());
  }
}
