import 'package:get/get.dart';

import 'sc_cr_material_add_chapter_logic.dart';

class ScCrMaterialAddChapterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScCrMaterialAddChapterLogic());
  }
}
