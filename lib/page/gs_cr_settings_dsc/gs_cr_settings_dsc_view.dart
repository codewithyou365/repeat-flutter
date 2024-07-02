import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

import 'gs_cr_settings_dsc_logic.dart';

class GsCrSettingsDscPage extends StatelessWidget {
  const GsCrSettingsDscPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrSettingsDscLogic>();
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
        ],
      ),
    );
  }

  openResetScheduleDialog(GsCrSettingsDscLogic logic) {
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
            logic.resetDailySchedule();
          },
        ),
      ],
    );
  }
}
