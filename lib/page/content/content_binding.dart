import 'package:get/get.dart';

import 'content_logic.dart';

class ContentBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ContentLogic());
  }
}
