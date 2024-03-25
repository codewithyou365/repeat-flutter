import 'package:get/get.dart';

import 'main_content_logic.dart';

class MainContentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MainContentLogic());
  }
}
