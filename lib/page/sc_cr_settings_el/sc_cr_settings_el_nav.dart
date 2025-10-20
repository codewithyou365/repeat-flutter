import 'package:get/get.dart';
import 'sc_cr_settings_el_binding.dart';
import 'sc_cr_settings_el_page.dart';

GetPage scCrSettingsElNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => ScCrSettingsElPage(),
    binding: ScCrSettingsElBinding(),
  );
}
