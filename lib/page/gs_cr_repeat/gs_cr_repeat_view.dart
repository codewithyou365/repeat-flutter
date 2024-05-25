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
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                buildContent(context, logic),
                buildBottom(logic),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildContent(BuildContext context, GsCrRepeatLogic logic) {
    var state = logic.state;
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

    Widget question = const Text("???");
    Widget? media;
    List<Widget> ret = [];
    for (int i = 0; i < showContent.length; i++) {
      var widget = buildInnerContent(context, showContent[i], state.segment);
      if (showContent[i] == ContentType.media) {
        media = widget;
      } else if (showContent[i] == ContentType.questionOrPrevAnswerOrTitle) {
        if (widget != null) {
          question = widget;
        }
      } else {
        var innerContent = widget;
        if (innerContent != null) {
          ret.add(innerContent);
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
    return Column(children: [
      Container(
        key: state.questionKey,
        child: question,
      ),
      if (media != null) media,
      Padding(
        padding: EdgeInsets.only(bottom: 15.h),
      ),
      Obx(() {
        if (state.questionHeight.value > 0) {
          var bottomHeight = 180.h;
          var mediaHeight = 0.h;
          if (media != null) {
            mediaHeight = 100.h;
          }
          return SizedBox(
            height: MediaQuery.of(context).size.height - bottomHeight - mediaHeight - state.questionHeight.value,
            child: ret.isEmpty ? const Text("") : ListView(children: ret),
          );
        }
        return const Text("");
      }),
    ]);
  }

  void afterLayout(_) {
    final state = Get.find<GsCrRepeatLogic>().state;
    var context = state.questionKey.currentContext;
    if (context == null) {
      return;
    }
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    state.questionHeight.value = renderBox.size.height;
  }

  Widget? buildInnerContent(BuildContext context, ContentType t, SegmentContent segment) {
    switch (t) {
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
      case ContentType.tip:
        if (segment.tip != "") {
          return Text(
            segment.tip,
            style: TextStyle(
              color: Theme.of(context).hintColor,
            ),
          );
        } else {
          return null;
        }
      case ContentType.answer:
        return Text(segment.answer);
      case ContentType.media:
        if (segment.mediaDocPath != "") {
          return PlayerBar(segment.segmentIndex, segment.mediaSegments, segment.mediaDocPath);
        } else {
          return null;
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
        return Row(
          children: [
            buildButton(I18nKey.btnKnow.tr, () => logic.show()),
            const Spacer(),
            buildButton(I18nKey.labelTips.tr, () => logic.tip()),
            const Spacer(),
            buildButton(I18nKey.btnUnknown.tr, () => logic.error()),
          ],
        );
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
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
