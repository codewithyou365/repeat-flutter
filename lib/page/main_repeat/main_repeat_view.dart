import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/page/main_repeat/main_repeat_state.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

import 'main_repeat_logic.dart';

class MainRepeatPage extends StatelessWidget {
  const MainRepeatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<MainRepeatLogic>();
    final state = Get.find<MainRepeatLogic>().state;

    return Scaffold(
        appBar: AppBar(
          title: Obx(() {
            return Text("${state.progress}/${state.total}");
          }),
        ),
        body: GetBuilder<MainRepeatLogic>(
          id: MainRepeatLogic.id,
          builder: (_) {
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(36.w),
                  child: buildContent(state),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.all(36.w),
                  child: buildBottom(logic),
                ),
              ],
            );
          },
        ));
  }

  Widget buildContent(MainRepeatState state) {
    switch (state.step) {
      case MainRepeatStep.recall:
        {
          switch (state.mode) {
            case MainRepeatMode.byValue:
              return Text(state.segmentValue.value);
            case MainRepeatMode.byMedia:
              return PlayerBar(state.segmentIndex.value, state.segments, state.lessonFilePath);
            default:
              return Text(state.segmentKey.value);
          }
        }
      default:
        {
          switch (state.mode) {
            case MainRepeatMode.byValue:
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.w),
                    child: Text(state.segmentValue.value),
                  ),
                  Text(state.segmentKey.value),
                  PlayerBar(state.segmentIndex.value, state.segments, state.lessonFilePath),
                ],
              );
            case MainRepeatMode.byMedia:
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.w),
                    child: PlayerBar(state.segmentIndex.value, state.segments, state.lessonFilePath),
                  ),
                  Text(state.segmentValue.value),
                  Text(state.segmentKey.value),
                ],
              );
            default:
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.w),
                    child: Text(state.segmentKey.value),
                  ),
                  Text(state.segmentValue.value),
                  PlayerBar(state.segmentIndex.value, state.segments, state.lessonFilePath),
                ],
              );
          }
        }
    }
  }

  Widget buildBottom(MainRepeatLogic logic) {
    switch (logic.state.step) {
      case MainRepeatStep.recall:
        return Row(
          children: [
            buildButton(I18nKey.btnShow.tr, () => logic.show()),
            const Spacer(),
            buildButton(I18nKey.btnUnknown.tr, () => logic.error()),
          ],
        );
      case MainRepeatStep.evaluate:
        return Row(
          children: [
            buildButton(I18nKey.btnKnow.tr, () => logic.know()),
            const Spacer(),
            buildButton(I18nKey.btnError.tr, () => logic.error(next: true)),
          ],
        );
      default:
        return Row(
          children: [
            buildButton(I18nKey.btnNext.tr, () => logic.next()),
          ],
        );
    }
  }

  Widget buildButton(String text, VoidCallback onPressed) {
    return TextButton(
      child: Text(text),
      onPressed: onPressed,
    );
  }
}
