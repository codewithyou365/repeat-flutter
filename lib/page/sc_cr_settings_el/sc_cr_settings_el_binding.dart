import 'package:get/get.dart';

import 'sc_cr_settings_el_logic.dart';

class ScCrSettingsElBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScCrSettingsElLogic());
  }
}
