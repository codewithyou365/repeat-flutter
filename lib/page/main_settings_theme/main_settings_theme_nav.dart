import 'package:get/get.dart';
import 'package:repeat_flutter/page/main_settings_theme/main_settings_theme_binding.dart';
import 'package:repeat_flutter/page/main_settings_theme/main_settings_theme_view.dart';

GetPage mainSettingsThemeNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => MainSettingsThemePage(),
    binding: MainSettingsThemeBinding(),
  );
}
