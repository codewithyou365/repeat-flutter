import 'package:get/get.dart';

import 'main_repeat_finish_logic.dart';

class MainRepeatFinishBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MainRepeatFinishLogic());
  }
}
