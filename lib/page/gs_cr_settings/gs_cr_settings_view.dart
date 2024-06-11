import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

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
            title: Text(I18nKey.labelResetSchedule.tr),
            onTap: () {
              openResetScheduleDialog(logic);
            },
          ),
        ],
      ),
    );
  }

  openResetScheduleDialog(GsCrSettingsLogic logic) {
    Get.defaultDialog(
      title: I18nKey.labelResetSchedule.tr,
      content: Text(I18nKey.labelResetScheduleDesc.tr),
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
