import 'package:get/get.dart';

import 'gs_cr_settings_dsc_logic.dart';

class GsCrSettingsDscBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsCrSettingsDscLogic());
  }
}
