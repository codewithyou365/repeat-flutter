import 'package:get/get.dart';

import 'gs_logic.dart';

class GsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsLogic());
  }
}
