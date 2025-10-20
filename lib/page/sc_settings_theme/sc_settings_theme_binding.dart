import 'package:get/get.dart';

import 'sc_settings_theme_logic.dart';

class ScSettingsThemeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScSettingsThemeLogic());
  }
}
