import 'package:get/get.dart';

import 'main_settings_logic.dart';

class MainSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MainSettingsLogic());
  }
}
