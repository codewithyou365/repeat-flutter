import 'package:get/get.dart';

import 'sc_settings_data_logic.dart';

class ScSettingsDataBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScSettingsDataLogic());
  }
}
