import 'package:get/get.dart';

import 'media_list_logic.dart';

class MediaListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MediaListLogic());
  }
}
