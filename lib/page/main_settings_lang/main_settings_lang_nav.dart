import 'package:get/get.dart';
import 'package:repeat_flutter/page/main_settings_lang/main_settings_lang_binding.dart';
import 'package:repeat_flutter/page/main_settings_lang/main_settings_lang_view.dart';

GetPage mainSettingsLangNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => MainSettingsLangPage(),
    binding: MainSettingsLangBinding(),
  );
}
