library i18n;

import 'config.dart';
import 'i18n_key.dart';

class ConfigEn extends Config {
  ConfigEn({Map<String, String>? defaultData}) : super(defaultData) {
    put(I18nKey.appName, "Repeat");
    put(I18nKey.settings, "Settings");
    put(I18nKey.language, "Language");
    put(I18nKey.theme, "Theme");
    put(I18nKey.themeDark, "Dart");
    put(I18nKey.themeLight, "Light");
  }
}
