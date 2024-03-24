import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/i18n/i18n_translations.dart';

import 'main_settings_lang_logic.dart';

class MainSettingsLangPage extends StatelessWidget {
  const MainSettingsLangPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<MainSettingsLangLogic>();

    return Scaffold(
        appBar: AppBar(
          title: Text(I18nKey.language.tr),
        ),
        body: ListView(
          children: <Widget>[
            ListTile(
              title: const Text('中文'),
              onTap: () => logic.set(I18nLocal.zh),
            ),
            ListTile(
              title: const Text('English'),
              onTap: () => logic.set(I18nLocal.en),
            ),
          ],
        )
    );
  }
}
