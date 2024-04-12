import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/page/main_repeat/main_repeat_state.dart';

import 'main_repeat_logic.dart';

class MainRepeatPage extends StatelessWidget {
  const MainRepeatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<MainRepeatLogic>();
    final state = Get.find<MainRepeatLogic>().state;
    logic.init();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          return Text("${state.progress}/${state.total}");
        }),
      ),
      body: Obx(() {
        return Column(
          children: [
            Text(state.segmentKey.value),
            Text(state.segmentValue.value),
            TextButton(
              child: Text(state.lessonFilePath.value),
              onPressed: () {
                logic.play(state.lessonFilePath.value);
              },
            ),
            buildBottom(logic),
          ],
        );
      }),
    );
  }

  Widget buildBottom(MainRepeatLogic logic) {
    switch (logic.state.step) {
      case MainRepeatStep.recall:
        return Row(
          children: [
            buildButton(I18nKey.btnShow.tr, () {}),
            const Spacer(),
            buildButton(I18nKey.btnUnknown.tr, () {}),
          ],
        );
      case MainRepeatStep.evaluate:
        return Row(
          children: [
            buildButton(I18nKey.btnKnow.tr, () {}),
            const Spacer(),
            buildButton(I18nKey.btnError.tr, () {}),
          ],
        );
      default:
        return buildButton(I18nKey.btnNext.tr, () {});
    }
  }

  Widget buildButton(String text, VoidCallback onPressed) {
    return TextButton(
      child: Text(text),
      onPressed: onPressed,
    );
  }
}
