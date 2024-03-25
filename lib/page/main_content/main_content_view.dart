import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

import 'main_content_logic.dart';

class MainContentPage extends StatelessWidget {
  const MainContentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<MainContentLogic>();
    final state = Get.find<MainContentLogic>().state;

    return Scaffold(
        appBar: AppBar(
          title: Text(I18nKey.theme.tr),
        ),
        body: ListView(
          children: <Widget>[
            ListTile(
              title: Text(I18nKey.themeDark.tr),
              onTap: () => {},
            ),
            ListTile(
              title: Text(I18nKey.themeLight.tr),
              onTap: () => {},
            ),
          ],
        )
    );
  }
}
