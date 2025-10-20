import 'package:get/get.dart';
import 'sc_cr_settings_rel_binding.dart';
import 'sc_cr_settings_rel_page.dart';

GetPage scCrSettingsRelNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => ScCrSettingsRelPage(),
    binding: ScCrSettingsRelBinding(),
  );
}
