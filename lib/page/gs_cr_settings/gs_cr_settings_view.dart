import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

import 'gs_cr_settings_logic.dart';

class GsCrSettingsPage extends StatelessWidget {
  const GsCrSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrSettingsLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.settings.tr),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(I18nKey.labelConfigSettingsForEl.tr),
            onLongPress: () {
              MsgBox.yes(I18nKey.labelTips.tr, I18nKey.labelConfigSettingsForElDesc.tr);
            },
            onTap: () {
              Nav.gsCrSettingsEl.push();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_applications),
            title: Text(I18nKey.labelConfigSettingsForRel.tr),
            onLongPress: () {
              MsgBox.yes(I18nKey.labelTips.tr, I18nKey.labelConfigSettingsForRelDesc.tr);
            },
            onTap: () {
              Nav.gsCrSettingsRel.push();
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_snippet),
            title: Text(I18nKey.labelDetailConfig.tr),
            onTap: logic.openConfig,
          ),
        ],
      ),
    );
  }
}
