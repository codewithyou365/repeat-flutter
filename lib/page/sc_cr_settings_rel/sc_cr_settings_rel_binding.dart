import 'package:get/get.dart';

import 'sc_cr_settings_rel_logic.dart';

class ScCrSettingsRelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScCrSettingsRelLogic());
  }
}
