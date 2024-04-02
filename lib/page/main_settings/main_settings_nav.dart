import 'package:get/get.dart';
import 'package:repeat_flutter/page/main_settings/main_settings_binding.dart';
import 'package:repeat_flutter/page/main_settings/main_settings_view.dart';

GetPage mainSettingsNav(String path) {
  return GetPage(
    name: path,
    transition: Transition.rightToLeft,
    page: () => MainSettingsPage(),
    binding: MainSettingsBinding(),
  );
}
