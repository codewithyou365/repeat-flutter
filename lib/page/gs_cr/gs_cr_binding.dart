import 'package:get/get.dart';

import 'gs_cr_logic.dart';

class GsCrBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsCrLogic());
  }
}
