import 'package:get/get.dart';

import 'main_repeat_logic.dart';

class MainRepeatBinding extends Bindings {
  @override
  void dependencies() {

    Get.lazyPut(() => MainRepeatLogic());
  }
}
