import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/i18n/i18n_translations.dart';
import 'package:repeat_flutter/main.dart';

import 'sc_settings_lang_logic.dart';

class ScSettingsLangPage extends StatelessWidget {
  const ScSettingsLangPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScSettingsLangLogic>();
    final appLogic = Get.find<MyAppLogic>();

    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.language.tr),
      ),
      body: Obx(() {
        final curr = appLogic.i18nLocal.value;
        return ListView(
          children: [
            for (final lang in I18nLocal.values)
              ListTile(
                title: Text(lang.displayName),
                trailing: lang == curr ? const Icon(Icons.check) : null,
                onTap: () => logic.set(lang),
              ),
          ],
        );
      }),
    );
  }
}
