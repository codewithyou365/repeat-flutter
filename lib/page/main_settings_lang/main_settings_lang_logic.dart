import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_translations.dart';
import 'package:repeat_flutter/nav.dart';

import 'main_settings_lang_state.dart';

class MainSettingsLangLogic extends GetxController {
  final MainSettingsLangState state = MainSettingsLangState();

  set(I18nLocal lang) {
    Get.updateLocale(lang.locale);
  }
}
