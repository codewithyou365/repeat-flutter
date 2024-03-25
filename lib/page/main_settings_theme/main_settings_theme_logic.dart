import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/main.dart';

import 'main_settings_theme_state.dart';

class MainSettingsThemeLogic extends GetxController {
  final MainSettingsThemeState state = MainSettingsThemeState();

  set(ThemeMode mode) {
    var myAppLogic = Get.find<MyAppLogic>();
    myAppLogic.themeMode.value = mode;
  }
}
