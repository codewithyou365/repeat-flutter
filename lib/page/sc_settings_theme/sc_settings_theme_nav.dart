import 'package:get/get.dart';
import 'sc_settings_theme_binding.dart';
import 'sc_settings_theme_page.dart';

GetPage scSettingsThemeNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => ScSettingsThemePage(),
    binding: ScSettingsThemeBinding(),
  );
}
