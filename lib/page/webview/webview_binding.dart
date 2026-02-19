import 'package:get/get.dart';

import 'webview_logic.dart';

class WebviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => WebviewLogic());
  }
}