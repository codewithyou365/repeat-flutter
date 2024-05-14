import 'package:get/get.dart';

import 'gs_settings_data_logic.dart';

class GsSettingsDataBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsSettingsDataLogic());
  }
}
