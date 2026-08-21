import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

import 'sc_settings_content_logic.dart';

class ScSettingsContentPage extends StatelessWidget {
  const ScSettingsContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScSettingsContentLogic>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.content.tr),
      ),
      body: Obx(
        () => ListView(
          children: <Widget>[
            SwitchListTile(
              title: Text(I18nKey.contentWebNetwork.tr),
              subtitle: Text(I18nKey.contentWebNetworkDesc.tr, style: theme.textTheme.bodySmall),
              value: logic.state.webNetwork.value,
              onChanged: logic.setWebNetwork,
            ),
          ],
        ),
      ),
    );
  }
}
