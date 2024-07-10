import 'package:get/get.dart';

import 'gs_cr_settings_rel_logic.dart';

class GsCrSettingsRelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsCrSettingsRelLogic());
  }
}
