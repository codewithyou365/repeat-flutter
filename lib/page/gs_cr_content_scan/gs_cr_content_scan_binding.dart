import 'package:get/get.dart';

import 'gs_cr_content_scan_logic.dart';

class GsCrContentScanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsCrContentScanLogic());
  }
}
