import 'package:get/get.dart';

import 'gs_cr_content_logic.dart';

class GsCrContentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsCrContentLogic());
  }
}
