import 'package:get/get.dart';

import 'sc_share_logic.dart';

class ScShareBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScShareLogic());
  }
}
