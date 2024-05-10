import 'package:get/get.dart';

import 'gs_cr_repeat_finish_logic.dart';

class GsCrRepeatFinishBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsCrRepeatFinishLogic());
  }
}
