import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

import 'gs_settings_theme_logic.dart';

class GsSettingsThemePage extends StatelessWidget {
  const GsSettingsThemePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsSettingsThemeLogic>();

    return Scaffold(
        appBar: AppBar(
          title: Text(I18nKey.theme.tr),
        ),
        body: ListView(
          children: <Widget>[
            ListTile(
              title: Text(I18nKey.themeDark.tr),
              onTap: () => {logic.set(ThemeMode.dark)},
            ),
            ListTile(
              title: Text(I18nKey.themeLight.tr),
              onTap: () => {logic.set(ThemeMode.light)},
            ),
          ],
        )
    );
  }
}
