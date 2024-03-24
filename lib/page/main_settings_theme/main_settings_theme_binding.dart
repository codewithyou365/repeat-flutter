import 'package:get/get.dart';

import 'main_settings_theme_logic.dart';

class MainSettingsThemeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MainSettingsThemeLogic());
  }
}
