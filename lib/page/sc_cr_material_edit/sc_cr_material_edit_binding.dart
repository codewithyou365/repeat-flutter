import 'package:get/get.dart';

import 'sc_cr_material_edit_logic.dart';

class ScCrMaterialEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScCrMaterialEditLogic());
  }
}
