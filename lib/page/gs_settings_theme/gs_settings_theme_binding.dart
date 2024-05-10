import 'package:get/get.dart';

import 'gs_settings_theme_logic.dart';

class GsSettingsThemeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsSettingsThemeLogic());
  }
}
