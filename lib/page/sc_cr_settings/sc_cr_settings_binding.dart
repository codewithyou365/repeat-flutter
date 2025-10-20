import 'package:get/get.dart';

import 'sc_cr_settings_logic.dart';

class ScCrSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScCrSettingsLogic());
  }
}
