import 'package:get/get.dart';
import 'gs_settings_lang_binding.dart';
import 'gs_settings_lang_view.dart';

GetPage gsSettingsLangNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => GsSettingsLangPage(),
    binding: GsSettingsLangBinding(),
  );
}
