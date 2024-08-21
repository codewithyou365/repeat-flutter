import 'package:get/get.dart';

import 'gs_cr_content_share_logic.dart';

class GsCrContentShareBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsCrContentShareLogic());
  }
}
