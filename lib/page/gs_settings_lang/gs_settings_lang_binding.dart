import 'package:get/get.dart';

import 'gs_settings_lang_logic.dart';

class GsSettingsLangBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GsSettingsLangLogic());
  }
}
