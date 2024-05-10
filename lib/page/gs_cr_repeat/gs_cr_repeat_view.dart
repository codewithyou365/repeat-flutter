import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'gs_cr_repeat_state.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

import 'gs_cr_repeat_logic.dart';

class GsCrRepeatPage extends StatelessWidget {
  const GsCrRepeatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrRepeatLogic>();
    final state = Get.find<GsCrRepeatLogic>().state;

    return Scaffold(
        appBar: AppBar(
          title: GetBuilder<GsCrRepeatLogic>(
            id: GsCrRepeatLogic.id,
            builder: (_) {
              return Text("${state.progress}/${state.total}-${state.segment.k}");
            },
          ),
        ),
        body: GetBuilder<GsCrRepeatLogic>(
          id: GsCrRepeatLogic.id,
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

  Widget buildContent(GsCrRepeatState state) {
    switch (state.step) {
      case RepeatStep.recall:
        {
          switch (state.mode) {
            case RepeatMode.byQuestion:
              return Text(state.segment.question);
            case RepeatMode.byMedia:
              return PlayerBar(state.segment.segmentIndex, state.segment.mediaSegments, state.segment.mediaDocPath);
            default:
              return Text(state.segment.answer);
          }
        }
      default:
        {
          switch (state.mode) {
            case RepeatMode.byQuestion:
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.w),
                    child: Text(state.segment.question),
                  ),
                  Text(state.segment.answer),
                  PlayerBar(state.segment.segmentIndex, state.segment.mediaSegments, state.segment.mediaDocPath),
                ],
              );
            case RepeatMode.byMedia:
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.w),
                    child: PlayerBar(state.segment.segmentIndex, state.segment.mediaSegments, state.segment.mediaDocPath),
                  ),
                  Text(state.segment.question),
                  Text(state.segment.answer),
                ],
              );
            default:
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.w),
                    child: Text(state.segment.answer),
                  ),
                  Text(state.segment.question),
                  PlayerBar(state.segment.segmentIndex, state.segment.mediaSegments, state.segment.mediaDocPath),
                ],
              );
          }
        }
    }
  }

  Widget buildBottom(GsCrRepeatLogic logic) {
    switch (logic.state.step) {
      case RepeatStep.recall:
        return Row(
          children: [
            buildButton(I18nKey.btnKnow.tr, () => logic.show()),
            const Spacer(),
            buildButton(I18nKey.btnUnknown.tr, () => logic.error()),
          ],
        );
      case RepeatStep.evaluate:
        return Row(
          children: [
            buildButton(I18nKey.btnNext.tr, () => logic.know(autoNext: true)),
            const Spacer(),
            buildButton(I18nKey.btnError.tr, () => logic.error()),
          ],
        );
      default:
        if (logic.state.c.isEmpty) {
          return Row(
            children: [
              buildButton(I18nKey.btnFinish.tr, () => logic.next()),
            ],
          );
        } else {
          return Row(
            children: [
              buildButton(I18nKey.btnNext.tr, () => logic.next()),
            ],
          );
        }
    }
  }

  Widget buildButton(String text, VoidCallback onPressed) {
    return TextButton(
      child: Text(text),
      onPressed: onPressed,
    );
  }
}
