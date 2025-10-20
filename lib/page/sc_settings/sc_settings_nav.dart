import 'package:get/get.dart';
import 'sc_settings_binding.dart';
import 'sc_settings_page.dart';

GetPage scSettingsNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => ScSettingsPage(),
    binding: ScSettingsBinding(),
  );
}
