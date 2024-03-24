import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/main.dart';

import 'main_settings_theme_state.dart';

class MainSettingsThemeLogic extends GetxController {
  final MainSettingsThemeState state = MainSettingsThemeState();

  set(ThemeMode mode) {
    Get.changeThemeMode(mode);
    if (mode == ThemeMode.dark) {
      Get.changeTheme(ThemeData.dark());
    } else if (mode == ThemeMode.light) {
      Get.changeTheme(ThemeData.light());
    }
  }
}
