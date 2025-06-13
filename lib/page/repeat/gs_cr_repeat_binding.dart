import 'package:get/get.dart';

import 'gs_cr_repeat_logic.dart';

class GsCrRepeatBinding extends Bindings {
  @override
  void dependencies() {

    Get.lazyPut(() => GsCrRepeatLogic());
  }
}
