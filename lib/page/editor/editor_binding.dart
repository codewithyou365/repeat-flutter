import 'package:get/get.dart';

import 'editor_logic.dart';

class EditorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EditorLogic());
  }
}
