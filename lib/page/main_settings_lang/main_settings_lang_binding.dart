import 'package:get/get.dart';

import 'main_settings_lang_logic.dart';

class MainSettingsLangBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MainSettingsLangLogic());
  }
}
