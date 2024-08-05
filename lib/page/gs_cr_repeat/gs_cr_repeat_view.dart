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

    return GetBuilder<GsCrRepeatLogic>(
      id: GsCrRepeatLogic.id,
      builder: (_) {
        var currIndex = 0;
        if (state.justView) {
          currIndex = state.justViewIndex + 1;
        } else {
          currIndex = state.progress + state.fakeKnow;
        }
        return Scaffold(
          appBar: AppBar(
            title: Text("$currIndex/${state.total}-${state.segment.k}"),
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: buildContent(context, logic, 590.h),
          ),
          bottomNavigationBar: buildBottom(logic, 60.h),
        );
      },
    );
  }

  Widget buildContent(BuildContext context, GsCrRepeatLogic logic, double height) {
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
      var w = buildInnerContent(logic, context, showContent[i].contentType, state.segment);
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
      height: height,
      child: listViewContent.isEmpty ? const Text("") : ListView(children: listViewContent),
    );
  }

  void afterLayout(_) {
    final state = Get.find<GsCrRepeatLogic>().state;
    if (state.skipAfterLayoutLogic) {
      state.skipAfterLayoutLogic = false;
      return;
    }
    if (state.tryNeedPlayQuestion) {
      state.questionMediaKey.currentState?.moveByIndex();
    } else {
      state.questionMediaKey.currentState?.stopMove();
    }

    if (state.tryNeedPlayAnswer) {
      state.answerMediaKey.currentState?.moveByIndex();
    } else {
      state.answerMediaKey.currentState?.stopMove();
    }
  }

  Widget? buildInnerContent(GsCrRepeatLogic logic, BuildContext context, ContentType t, SegmentContent segment) {
    GsCrRepeatState state = logic.state;
    switch (t) {
      case ContentType.questionOrPrevAnswerOrTitleMedia:
        if (segment.question != "" && segment.mediaDocPath != "" && segment.qMediaSegments.isNotEmpty) {
          return PlayerBar(state.questionMediaId, 0, [segment.qMediaSegments[segment.segmentIndex]], segment.mediaDocPath, key: state.questionMediaKey);
        } else if (segment.prevAnswer != "" && segment.mediaDocPath != "") {
          return PlayerBar(state.questionMediaId, 0, [segment.aMediaSegments[segment.segmentIndex - 1]], segment.mediaDocPath, key: state.questionMediaKey);
        } else if (segment.title != "" && segment.mediaDocPath != "" && segment.titleMediaSegment != null) {
          return PlayerBar(state.questionMediaId, 0, [segment.titleMediaSegment!], segment.mediaDocPath, key: state.questionMediaKey);
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
          return PlayerBar(
            state.answerMediaId,
            segment.segmentIndex,
            segment.aMediaSegments,
            segment.mediaDocPath,
            key: state.answerMediaKey,
          );
        }
        return null;
      case ContentType.answerMediaWithPnController:
        if (segment.mediaDocPath != "") {
          return PlayerBar(
            state.answerMediaId,
            segment.segmentIndex,
            segment.aMediaSegments,
            segment.mediaDocPath,
            key: state.answerMediaKey,
            onPrevious: logic.minusPnOffset,
            onReplay: logic.resetPnOffset,
            onNext: logic.plusPnOffset,
          );
        }
        return null;
      case ContentType.answerPnController:
        if (segment.mediaDocPath != "") {
          return buildMediaController(logic, state.answerMediaKey);
        }
        return null;
      case ContentType.answer:
        return Text(segment.answer);
      case ContentType.tip:
        if (segment.tip != "") {
          return Text(
            segment.tip,
            style: TextStyle(color: Theme.of(context).hintColor),
          );
        }
        return null;
      default:
        return Padding(
          padding: EdgeInsets.only(bottom: 8.w),
        );
    }
  }

  Widget buildBottom(GsCrRepeatLogic logic, double height) {
    var state = logic.state;
    var leftButtonText = "";
    var rightButtonText = "";
    void Function() leftButtonLogic = () => {};
    void Function() rightButtonLogic = () => {};
    if (state.justView) {
      switch (state.step) {
        case RepeatStep.recall:
          leftButtonText = I18nKey.btnShow.tr;
          leftButtonLogic = logic.showForJustView;
          rightButtonText = I18nKey.btnPrevious.tr;
          rightButtonLogic = logic.previousForJustView;
          break;
        case RepeatStep.evaluate:
          leftButtonText = I18nKey.btnNext.tr;
          leftButtonLogic = logic.nextForJustView;
          rightButtonText = I18nKey.btnPrevious.tr;
          rightButtonLogic = logic.previousForJustView;
          break;
        case RepeatStep.finish:
          leftButtonText = I18nKey.btnFinish.tr;
          leftButtonLogic = logic.finish;
          break;
      }
    } else {
      switch (state.step) {
        case RepeatStep.recall:
          leftButtonText = I18nKey.btnKnow.tr;
          leftButtonLogic = logic.show;
          rightButtonText = I18nKey.btnUnknown.tr;
          rightButtonLogic = logic.error;
          break;
        case RepeatStep.evaluate:
          leftButtonText = "${I18nKey.btnNext.tr}\n${state.nextKey}";
          leftButtonLogic = () => logic.know(autoNext: true);
          rightButtonText = I18nKey.btnError.tr;
          rightButtonLogic = logic.error;
          break;
        case RepeatStep.finish:
          if (logic.state.c.isEmpty) {
            leftButtonText = I18nKey.btnFinish.tr;
            leftButtonLogic = logic.next;
          } else {
            leftButtonText = "${I18nKey.btnNext.tr}\n${state.nextKey}";
            leftButtonLogic = logic.next;
          }
          break;
      }
    }

    return Stack(
      children: [
        Row(
          children: [
            buildButton(leftButtonText, leftButtonLogic, height, width: 180.w),
            const Spacer(),
            buildButton(rightButtonText, rightButtonLogic, height, width: 180.w),
          ],
        ),
        if (!state.openTip)
          Row(
            children: [
              const Spacer(),
              buildButton(I18nKey.btnTips.tr, () => logic.tip(), height, width: 180.w),
              const Spacer(),
            ],
          )
      ],
    );
  }

  Widget buildMediaController(GsCrRepeatLogic logic, GlobalKey<PlayerBarState> p) {
    return Row(
      children: [
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 30.w,
          onPressed: logic.minusPnOffset,
        ),
        IconButton(
          icon: const Icon(Icons.replay),
          iconSize: 30.w,
          onPressed: logic.resetPnOffset,
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 30.w,
          onPressed: logic.plusPnOffset,
        ),
      ],
    );
  }

  Widget buildButton(String text, VoidCallback onPressed, double height, {double? width}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        child: Text(text),
      ),
    );
  }
}
