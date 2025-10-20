import 'package:get/get.dart';
import 'sc_cr_settings_binding.dart';
import 'sc_cr_settings_page.dart';

GetPage scCrSettingsNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => ScCrSettingsPage(),
    binding: ScCrSettingsBinding(),
  );
}
