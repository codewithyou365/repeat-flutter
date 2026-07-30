import 'package:get/get.dart';

import 'sc_cr_material_search_logic.dart';

class ScCrMaterialSearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScCrMaterialSearchLogic());
  }
}
