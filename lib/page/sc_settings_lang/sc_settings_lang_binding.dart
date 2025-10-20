import 'package:get/get.dart';

import 'sc_settings_lang_logic.dart';

class ScSettingsLangBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScSettingsLangLogic());
  }
}
