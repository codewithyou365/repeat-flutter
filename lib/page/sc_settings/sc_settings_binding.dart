import 'package:get/get.dart';

import 'sc_settings_logic.dart';

class ScSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScSettingsLogic());
  }
}
