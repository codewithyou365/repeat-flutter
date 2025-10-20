import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';

import 'sc_settings_logic.dart';

class ScSettingsPage extends StatelessWidget {
  const ScSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScSettingsLogic>();
    return Scaffold(
        appBar: AppBar(
          title: Text(I18nKey.settings.tr),
        ),
        body: ListView(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(I18nKey.language.tr),
              onTap: () {
                Nav.scSettingsLang.push();
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: Text(I18nKey.theme.tr),
              onTap: () {
                Nav.scSettingsTheme.push();
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: Text(I18nKey.data.tr),
              onTap: () {
                Nav.scSettingsData.push();
              },
            ),
          ],
        ));
  }
}
