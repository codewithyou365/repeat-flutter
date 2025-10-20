import 'package:get/get.dart';
import 'sc_settings_lang_binding.dart';
import 'sc_settings_lang_page.dart';

GetPage scSettingsLangNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => ScSettingsLangPage(),
    binding: ScSettingsLangBinding(),
  );
}
