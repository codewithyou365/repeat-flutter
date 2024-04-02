import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

import 'main_repeat_logic.dart';

class MainRepeatPage extends StatelessWidget {
  const MainRepeatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<MainRepeatLogic>();
    final state = Get.find<MainRepeatLogic>().state;

    return Scaffold(
        appBar: AppBar(
          title: Text(I18nKey.btnRepeat.tr),
        ),
        body: ListView(
          children: const <Widget>[
            ListTile(
              title: Text('Hello'),
            ),
          ],
        ));
  }
}
