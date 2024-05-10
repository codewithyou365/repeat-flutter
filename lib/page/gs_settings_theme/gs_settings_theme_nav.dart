import 'package:get/get.dart';
import 'gs_settings_theme_binding.dart';
import 'gs_settings_theme_view.dart';

GetPage gsSettingsThemeNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => GsSettingsThemePage(),
    binding: GsSettingsThemeBinding(),
  );
}
