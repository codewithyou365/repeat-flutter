import 'package:get/get.dart';

import 'repeat_logic.dart';

class RepeatBinding extends Bindings {
  @override
  void dependencies() {

    Get.lazyPut(() => RepeatLogic());
  }
}
