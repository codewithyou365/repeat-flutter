import 'package:get/get.dart';

import 'gs_settings_logic.dart';

class GsSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsSettingsLogic());
  }
}
