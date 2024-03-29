library i18n;

import 'config.dart';
import 'i18n_key.dart';

class ConfigEn extends Config {
  ConfigEn({Map<String, String>? defaultData}) : super(defaultData) {
    put(I18nKey.appName, "Repeat");
    put(I18nKey.settings, "Settings");
    put(I18nKey.content, "Content");
    put(I18nKey.statistic, "Stats");
    put(I18nKey.language, "Language");
    put(I18nKey.theme, "Theme");
    put(I18nKey.themeDark, "Dart");
    put(I18nKey.themeLight, "Light");
    put(I18nKey.btnDelete, "Delete");
    put(I18nKey.btnEdit, "Edit");
    put(I18nKey.btnCopy, "Copy");
    put(I18nKey.btnDownload, "Download");
  }
}
