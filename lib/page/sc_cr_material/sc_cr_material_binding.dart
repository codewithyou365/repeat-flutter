import 'package:get/get.dart';

import 'sc_cr_material_logic.dart';

class ScCrMaterialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScCrMaterialLogic());
  }
}
