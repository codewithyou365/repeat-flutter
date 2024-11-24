import 'package:get/get.dart';

import 'gs_cr_content_template_logic.dart';

class GsCrContentTemplateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsCrContentTemplateLogic());
  }
}
