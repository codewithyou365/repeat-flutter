import 'package:get/get.dart';
import 'sc_settings_ai_binding.dart';
import 'sc_settings_ai_page.dart';

GetPage scSettingsAiNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => const ScSettingsAiPage(),
    binding: ScSettingsAiBinding(),
  );
}
