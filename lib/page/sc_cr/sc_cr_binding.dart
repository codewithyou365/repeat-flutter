import 'package:get/get.dart';

import 'sc_cr_logic.dart';

class ScCrBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScCrLogic());
  }
}
