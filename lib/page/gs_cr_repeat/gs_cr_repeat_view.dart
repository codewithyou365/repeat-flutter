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
    Widget? questionMedia;
    Widget question = const Text("???");
    Widget? answerMedia;

    List<Widget> listViewContent = [];
    for (int i = 0; i < showContent.length; i++) {
      if (showContent[i] == ContentType.questionOrPrevAnswerOrTitle) {
        var textAndMedia = buildInnerContent(state, context, ContentType.questionOrPrevAnswerOrTitle, state.segment);
        question = textAndMedia[0];
        if (textAndMedia.length == 2) {
          questionMedia = textAndMedia[1];
        }
      } else if (showContent[i] == ContentType.answer) {
        var textAndMedia = buildInnerContent(state, context, ContentType.answer, state.segment);
        listViewContent.add(textAndMedia[0]);
        if (textAndMedia.length == 2) {
          answerMedia = textAndMedia[1];
        }
      } else {
        var innerContent = buildInnerContent(state, context, showContent[i], state.segment);
        for (Widget w in innerContent) {
          listViewContent.add(w);
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
    return Column(children: [
      if (questionMedia != null) questionMedia,
      Container(
        key: state.questionKey,
        child: question,
      ),
      if (answerMedia != null) answerMedia,
      Padding(
        padding: EdgeInsets.only(bottom: 15.h),
      ),
      Obx(() {
        if (state.questionHeight.value > 0) {
          var bottomHeight = 180.h;
          var mediaHeight = 0.h;
          if (questionMedia != null) {
            mediaHeight += 100.h;
          }
          if (answerMedia != null) {
            mediaHeight += 100.h;
          }
          return SizedBox(
            height: MediaQuery.of(context).size.height - bottomHeight - mediaHeight - state.questionHeight.value,
            child: listViewContent.isEmpty ? const Text("") : ListView(children: listViewContent),
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
    if (state.step == RepeatStep.recall) {
      state.questionMediaKey.currentState?.autoMove(offset: 0.0);
    } else {
      state.questionMediaKey.currentState?.stopAutoMove();
    }
  }

  List<Widget> buildInnerContent(GsCrRepeatState state, BuildContext context, ContentType t, SegmentContent segment) {
    List<Widget> ret = [];
    switch (t) {
      case ContentType.questionOrPrevAnswerOrTitle:
        if (segment.question != "") {
          if (segment.mediaDocPath != "" && segment.qMediaSegments.isNotEmpty) {
            ret.add(Text(segment.question));
            ret.add(PlayerBar(segment.segmentIndex, segment.qMediaSegments, segment.mediaDocPath, key: state.questionMediaKey));
            return ret;
          }
          ret.add(Text(segment.question));
          return ret;
        } else if (segment.prevAnswer != "") {
          if (segment.mediaDocPath != "") {
            ret.add(Text(segment.prevAnswer));
            ret.add(PlayerBar(0, [segment.aMediaSegments[segment.segmentIndex - 1]], segment.mediaDocPath, key: state.questionMediaKey));
            return ret;
          }
          ret.add(Text(segment.prevAnswer));
          return ret;
        } else if (segment.title != "") {
          if (segment.mediaDocPath != "" && segment.titleMediaSegment != null) {
            ret.add(Text(segment.title));
            ret.add(PlayerBar(0, [segment.titleMediaSegment!], segment.mediaDocPath, key: state.questionMediaKey));
            return ret;
          }
          ret.add(Text(segment.title));
          return ret;
        } else {
          ret.add(const Text("???"));
          return ret;
        }
      case ContentType.answer:
        if (segment.mediaDocPath != "") {
          ret.add(Text(segment.answer));
          ret.add(PlayerBar(segment.segmentIndex, segment.aMediaSegments, segment.mediaDocPath));
          return ret;
        }
        ret.add(Text(segment.answer));
        return ret;
      case ContentType.tip:
        if (segment.tip != "") {
          ret.add(Text(
            segment.tip,
            style: TextStyle(
              color: Theme.of(context).hintColor,
            ),
          ));
          return ret;
        }
        return [];
      default:
        ret.add(Padding(
          padding: EdgeInsets.only(bottom: 8.w),
        ));
        return ret;
    }
  }

  Widget buildBottom(GsCrRepeatLogic logic) {
    switch (logic.state.step) {
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
