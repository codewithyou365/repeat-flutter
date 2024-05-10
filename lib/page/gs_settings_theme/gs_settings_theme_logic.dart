import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/main.dart';

import 'gs_settings_theme_state.dart';

class GsSettingsThemeLogic extends GetxController {
  final GsSettingsThemeState state = GsSettingsThemeState();

  set(ThemeMode mode) {
    var myAppLogic = Get.find<MyAppLogic>();
    myAppLogic.themeMode.value = mode;
    var kv = Kv(K.settingsTheme, myAppLogic.themeMode.value.name);
    Db().db.kvDao.insertKv(kv);
  }
}
