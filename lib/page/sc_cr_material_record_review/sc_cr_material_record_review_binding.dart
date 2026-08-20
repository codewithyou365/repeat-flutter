import 'package:get/get.dart';

import 'sc_cr_material_record_review_logic.dart';

class ScCrMaterialRecordReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScCrMaterialRecordReviewLogic());
  }
}
