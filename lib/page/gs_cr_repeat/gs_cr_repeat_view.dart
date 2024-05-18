import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
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
              if (state.step == RepeatStep.recall)
                InkWell(
                  onTap: () => {logic.tryToTip()},
                  child: Text(I18nKey.labelTips.tr),
                ),
              Padding(
                padding: EdgeInsets.all(36.w),
                child: buildBottom(logic),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildContent(GsCrRepeatState state) {
    state.step.index;
    List<List<ContentType>> currProcessContent;
    var processIndex = state.progress;
    if (processIndex < 0) {
      currProcessContent = state.showContent[0];
    } else if (processIndex < state.showContent.length) {
      currProcessContent = state.showContent[processIndex];
    } else {
      currProcessContent = state.showContent[state.showContent.length - 1];
    }
    List<ContentType> showContent;
    if (state.step.index < currProcessContent.length) {
      showContent = currProcessContent[state.step.index];
    } else {
      showContent = currProcessContent[currProcessContent.length - 1];
    }

    if (showContent.length == 1) {
      return buildInnerContent(showContent[0], state.segment);
    }
    List<Widget> ret = [];
    for (int i = 0; i < showContent.length; i++) {
      ret.add(buildInnerContent(showContent[i], state.segment));
    }

    return Column(children: ret);
  }

  Widget buildInnerContent(ContentType t, SegmentContent segment) {
    switch (t) {
      case ContentType.question:
        return Text(segment.question);
      case ContentType.media:
        return PlayerBar(segment.segmentIndex, segment.mediaSegments, segment.mediaDocPath);
      case ContentType.answer:
        return Text(segment.answer);
      case ContentType.prevAnswerOrTitle:
        if (segment.prevAnswer != "") {
          return Text(segment.prevAnswer);
        } else {
          return Text(segment.title);
        }
      default:
        return Padding(
          padding: EdgeInsets.only(bottom: 8.w),
        );
    }
  }

  Widget buildBottom(GsCrRepeatLogic logic) {
    switch (logic.state.step) {
      case RepeatStep.recall:
      case RepeatStep.tip:
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
