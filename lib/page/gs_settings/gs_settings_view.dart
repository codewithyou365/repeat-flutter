import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';

import 'gs_settings_logic.dart';

class GsSettingsPage extends StatelessWidget {
  const GsSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsSettingsLogic>();
    return Scaffold(
        appBar: AppBar(
          title: Text(I18nKey.settings.tr),
        ),
        body: ListView(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(I18nKey.language.tr),
              onTap: () {
                Nav.gsSettingsLang.push();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(I18nKey.theme.tr),
              onTap: () {
                Nav.gsSettingsTheme.push();
              },
            ),
            ListTile(
              leading: const Icon(Icons.dataset),
              title: Text(I18nKey.data.tr),
              onTap: () {
                Nav.gsSettingsData.push();
              },
            ),
          ],
        ));
  }
}
