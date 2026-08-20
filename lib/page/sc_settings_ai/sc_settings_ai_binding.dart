import 'package:get/get.dart';

import 'sc_settings_ai_logic.dart';

class ScSettingsAiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScSettingsAiLogic());
  }
}
