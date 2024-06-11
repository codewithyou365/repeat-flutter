import 'package:get/get.dart';

import 'gs_cr_settings_logic.dart';

class GsCrSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsCrSettingsLogic());
  }
}
