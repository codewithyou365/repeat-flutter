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
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: buildContent(context, logic),
              ),
              buildBottom(logic),
            ],
          );
        },
      ),
    );
  }

  Widget buildContent(BuildContext context, GsCrRepeatLogic logic) {
    var state = logic.state;
    state.step.index;
    var currProcessShowContent = logic.getCurrProcessShowContent();
    List<ContentTypeWithTip> showContent;
    if (state.step.index < currProcessShowContent.length) {
      showContent = currProcessShowContent[state.step.index];
    } else {
      showContent = currProcessShowContent[currProcessShowContent.length - 1];
    }

    List<Widget> listViewContent = [];
    for (int i = 0; i < showContent.length; i++) {
      var w = buildInnerContent(state, context, showContent[i].contentType, state.segment);
      if (w != null) {
        if (showContent[i].tip && state.openTip) {
          listViewContent.add(w);
        } else if (!showContent[i].tip) {
          listViewContent.add(w);
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(afterLayout);

    return SizedBox(
      height: 546.h,
      child: listViewContent.isEmpty ? const Text("") : ListView(children: listViewContent),
    );
  }

  void afterLayout(_) {
    final state = Get.find<GsCrRepeatLogic>().state;
    if (state.tryNeedPlayQuestion) {
      state.questionMediaKey.currentState?.move(offset: 0.0);
    } else {
      state.questionMediaKey.currentState?.stopMove();
    }

    if (state.tryNeedPlayAnswer) {
      state.answerMediaKey.currentState?.moveByIndex();
    } else {
      state.answerMediaKey.currentState?.stopMove();
    }
  }

  Widget? buildInnerContent(GsCrRepeatState state, BuildContext context, ContentType t, SegmentContent segment) {
    switch (t) {
      case ContentType.questionOrPrevAnswerOrTitleMedia:
        if (segment.question != "" && segment.mediaDocPath != "" && segment.qMediaSegments.isNotEmpty) {
          return PlayerBar(0, [segment.qMediaSegments[segment.segmentIndex]], segment.mediaDocPath, key: state.questionMediaKey);
        } else if (segment.prevAnswer != "" && segment.mediaDocPath != "") {
          return PlayerBar(0, [segment.aMediaSegments[segment.segmentIndex - 1]], segment.mediaDocPath, key: state.questionMediaKey);
        } else if (segment.title != "" && segment.mediaDocPath != "" && segment.titleMediaSegment != null) {
          return PlayerBar(0, [segment.titleMediaSegment!], segment.mediaDocPath, key: state.questionMediaKey);
        }
        return null;
      case ContentType.questionOrPrevAnswerOrTitle:
        if (segment.question != "") {
          return Text(segment.question);
        } else if (segment.prevAnswer != "") {
          return Text(segment.prevAnswer);
        } else if (segment.title != "") {
          return Text(segment.title);
        } else {
          return const Text("???");
        }
      case ContentType.answerMedia:
        if (segment.mediaDocPath != "") {
          return PlayerBar(segment.segmentIndex, segment.aMediaSegments, segment.mediaDocPath, key: state.answerMediaKey);
        }
        return null;
      case ContentType.answer:
        return Text(segment.answer);
      case ContentType.tip:
        if (segment.tip != "") {
          return Text(
            segment.tip,
            style: TextStyle(
              color: Theme.of(context).hintColor,
            ),
          );
        }
        return null;
      default:
        return Padding(
          padding: EdgeInsets.only(bottom: 8.w),
        );
    }
  }

  Widget buildBottom(GsCrRepeatLogic logic) {
    var state = logic.state;
    if (state.openTip) {
      switch (state.step) {
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
              buildButton("${I18nKey.btnNext.tr}\n${state.nextKey}", () => logic.know(autoNext: true)),
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
                buildButton("${I18nKey.btnNext.tr}\n${state.nextKey}", () => logic.next()),
              ],
            );
          }
      }
    } else {
      switch (state.step) {
        case RepeatStep.recall:
          return Row(
            children: [
              buildButton(I18nKey.btnKnow.tr, () => logic.show()),
              const Spacer(),
              buildButton(I18nKey.btnTips.tr, () => logic.tip()),
              const Spacer(),
              buildButton(I18nKey.btnUnknown.tr, () => logic.error()),
            ],
          );
        case RepeatStep.evaluate:
          return Row(
            children: [
              buildButton("${I18nKey.btnNext.tr}\n${state.nextKey}", () => logic.know(autoNext: true)),
              const Spacer(),
              buildButton(I18nKey.btnTips.tr, () => logic.tip()),
              const Spacer(),
              buildButton(I18nKey.btnError.tr, () => logic.error()),
            ],
          );
        default:
          if (logic.state.c.isEmpty) {
            return Row(
              children: [
                buildButton(I18nKey.btnFinish.tr, () => logic.next()),
                const Spacer(),
                buildButton(I18nKey.btnTips.tr, () => logic.tip()),
                const Spacer(),
                buildButton("", () => {}),
              ],
            );
          } else {
            return Row(
              children: [
                buildButton("${I18nKey.btnNext.tr}\n${state.nextKey}", () => logic.next()),
                const Spacer(),
                buildButton(I18nKey.btnTips.tr, () => logic.tip()),
                const Spacer(),
                buildButton("", () => {}),
              ],
            );
          }
      }
    }
  }

  Widget buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: 120.w,
      height: 50.h,
      child: TextButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}
