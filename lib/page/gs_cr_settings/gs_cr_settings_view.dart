import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';

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
            leading: const Icon(Icons.redo),
            title: Text(I18nKey.labelResetLearn.tr),
            onTap: () {
              openResetScheduleDialog(logic);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(I18nKey.labelLearnSettings.tr),
            onTap: () {
              Nav.gsCrSettingsDsc.push();
            },
          ),
        ],
      ),
    );
  }

  openResetScheduleDialog(GsCrSettingsLogic logic) {
    Get.defaultDialog(
      title: I18nKey.labelResetLearn.tr,
      content: Text(I18nKey.labelResetLearnDesc.tr),
      actions: [
        TextButton(
          child: Text(I18nKey.btnCancel.tr),
          onPressed: () {
            Get.back();
          },
        ),
        TextButton(
          child: Text(I18nKey.btnOk.tr),
          onPressed: () {
            logic.resetSchedule();
          },
        ),
      ],
    );
  }
}
