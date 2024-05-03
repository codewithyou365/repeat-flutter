import 'package:flutter/material.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';

class MainSettingsPage extends StatelessWidget {
  const MainSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                Nav.mainSettingsLang.push();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(I18nKey.theme.tr),
              onTap: () {
                Nav.mainSettingsTheme.push();
              },
            ),
            // TODO add sql query view
          ],
        ));
  }
}
