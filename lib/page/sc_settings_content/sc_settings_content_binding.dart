import 'package:get/get.dart';

import 'sc_settings_content_logic.dart';

class ScSettingsContentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScSettingsContentLogic());
  }
}
