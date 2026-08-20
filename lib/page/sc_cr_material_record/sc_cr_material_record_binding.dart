import 'package:get/get.dart';

import 'sc_cr_material_record_logic.dart';

class ScCrMaterialRecordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScCrMaterialRecordLogic());
  }
}
