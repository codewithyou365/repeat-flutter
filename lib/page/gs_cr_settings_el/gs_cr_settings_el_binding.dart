import 'package:get/get.dart';

import 'gs_cr_settings_el_logic.dart';

class GsCrSettingsElBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsCrSettingsElLogic());
  }
}
