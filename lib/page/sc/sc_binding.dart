import 'package:get/get.dart';

import 'sc_logic.dart';

class ScBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScLogic());
  }
}
