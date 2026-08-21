import 'package:get/get.dart';
import 'sc_settings_content_binding.dart';
import 'sc_settings_content_page.dart';

GetPage scSettingsContentNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => const ScSettingsContentPage(),
    binding: ScSettingsContentBinding(),
  );
}
