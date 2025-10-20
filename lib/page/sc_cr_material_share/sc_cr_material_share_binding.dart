import 'package:get/get.dart';

import 'sc_cr_material_share_logic.dart';

class ScCrMaterialShareBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScCrMaterialShareLogic());
  }
}
