import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

import 'gs_cr_repeat_logic.dart';
import 'gs_cr_repeat_state.dart';

typedef HideVideoPlayerBarCallback = void Function(PlayerBar playerBar);

class GsCrRepeatViewBasic {
  static Widget titleWidget(GsCrRepeatLogic logic) {
    var state = logic.state;
    var currIndex = 0;
    if (state.justView) {
      currIndex = state.justViewIndex + 1;
    } else {
      currIndex = state.progress + state.fakeKnow;
    }
    return Text("$currIndex/${state.total}-${state.segment.k}");
  }

  static Widget buildContent(BuildContext context, GsCrRepeatLogic logic, double height, {bool? left, HideVideoPlayerBarCallback? callback}) {
    var state = logic.state;
    state.step.index;
    var currProcessShowContent = logic.getCurrProcessShowContent();
    List<ContentArg> showContent;
    if (state.step.index < currProcessShowContent.length) {
      showContent = currProcessShowContent[state.step.index];
    } else {
      showContent = currProcessShowContent[currProcessShowContent.length - 1];
    }
    List<ContentType> validContentType = [];
    List<Widget> listViewContent = [];
    for (int i = 0; i < showContent.length; i++) {
      Widget? w;
      if (left != null) {
        if (left == showContent[i].left) {
          w = GsCrRepeatViewBasic.buildInnerContent(logic, context, showContent[i].contentType, showContent[i].withVideo ?? false, state.segment, callback);
        }
      } else {
        w = GsCrRepeatViewBasic.buildInnerContent(logic, context, showContent[i].contentType, showContent[i].withVideo ?? false, state.segment, callback);
      }
      if (w != null) {
        if (showContent[i].tip && state.openTip) {
          listViewContent.add(w);
        } else if (!showContent[i].tip) {
          listViewContent.add(w);
        }
        validContentType.add(showContent[i].contentType);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      logic.mediaLoad(validContentType);
    });

    return SizedBox(
      height: height,
      child: listViewContent.isEmpty ? const Text("") : ListView(children: listViewContent),
    );
  }

  static Widget? buildInnerContent(GsCrRepeatLogic logic, BuildContext context, ContentType t, bool? withVideo, SegmentContent segment, HideVideoPlayerBarCallback? callback) {
    GsCrRepeatState state = logic.state;
    switch (t) {
      case ContentType.questionOrPrevAnswerOrTitleMedia:
        if (segment.mediaDocPath != "" && segment.qMediaSegments.isNotEmpty) {
          var bar = PlayerBar(
            state.questionMediaId,
            0,
            [segment.qMediaSegments[segment.segmentIndex]],
            segment.mediaDocPath,
            withVideo: withVideo ?? false,
            key: state.questionMediaKey,
            onFullScreen: logic.onMediaFullScreen,
            onInited: logic.onMediaInited,
            initMaskRatio: logic.getMaskRatio(),
            setMaskRatio: logic.setMaskRatio,
          );
          if (callback != null && withVideo != null && withVideo == false) {
            callback(bar);
          }
          return bar;
        } else if (segment.question == "" && segment.mediaDocPath != "" && segment.aMediaSegments.isNotEmpty && segment.segmentIndex - 1 >= 0) {
          var bar = PlayerBar(
            state.questionMediaId,
            0,
            [segment.aMediaSegments[segment.segmentIndex - 1]],
            segment.mediaDocPath,
            withVideo: withVideo ?? false,
            key: state.questionMediaKey,
            onFullScreen: logic.onMediaFullScreen,
            onInited: logic.onMediaInited,
            initMaskRatio: logic.getMaskRatio(),
            setMaskRatio: logic.setMaskRatio,
          );
          if (callback != null && withVideo != null && withVideo == false) {
            callback(bar);
          }
          return bar;
        } else if (segment.question == "" && segment.mediaDocPath != "" && segment.titleMediaSegment != null) {
          var bar = PlayerBar(
            state.questionMediaId,
            0,
            [segment.titleMediaSegment!],
            segment.mediaDocPath,
            withVideo: withVideo ?? false,
            key: state.questionMediaKey,
            onFullScreen: logic.onMediaFullScreen,
            onInited: logic.onMediaInited,
            initMaskRatio: logic.getMaskRatio(),
            setMaskRatio: logic.setMaskRatio,
          );
          if (callback != null && withVideo != null && withVideo == false) {
            callback(bar);
          }
          return bar;
        }
        return null;
      case ContentType.questionOrPrevAnswerOrTitleMediaPncAndWom:
        if (segment.mediaDocPath != "" && segment.qMediaSegments.isNotEmpty) {
          var bar = PlayerBar(
            state.questionMediaId,
            0,
            [segment.qMediaSegments[segment.segmentIndex]],
            segment.mediaDocPath,
            withVideo: withVideo ?? false,
            key: state.questionMediaKey,
            initMaskRatio: logic.getMaskRatio(),
            onFullScreen: logic.onMediaFullScreen,
            onInited: logic.onMediaInited,
            onPrevious: logic.minusPnOffset,
            onReplay: logic.resetPnOffset,
            onNext: logic.plusPnOffset,
          );
          if (callback != null && withVideo != null && withVideo == false) {
            callback(bar);
          }
          return bar;
        } else if (segment.question == "" && segment.mediaDocPath != "" && segment.aMediaSegments.isNotEmpty && segment.segmentIndex - 1 >= 0) {
          var bar = PlayerBar(
            state.questionMediaId,
            0,
            [segment.aMediaSegments[segment.segmentIndex - 1]],
            segment.mediaDocPath,
            withVideo: withVideo ?? false,
            key: state.questionMediaKey,
            initMaskRatio: logic.getMaskRatio(),
            onFullScreen: logic.onMediaFullScreen,
            onInited: logic.onMediaInited,
            onPrevious: logic.minusPnOffset,
            onReplay: logic.resetPnOffset,
            onNext: logic.plusPnOffset,
          );
          if (callback != null && withVideo != null && withVideo == false) {
            callback(bar);
          }
          return bar;
        } else if (segment.question == "" && segment.mediaDocPath != "" && segment.titleMediaSegment != null) {
          var bar = PlayerBar(
            state.questionMediaId,
            0,
            [segment.titleMediaSegment!],
            segment.mediaDocPath,
            withVideo: withVideo ?? false,
            key: state.questionMediaKey,
            initMaskRatio: logic.getMaskRatio(),
            onFullScreen: logic.onMediaFullScreen,
            onInited: logic.onMediaInited,
            onPrevious: logic.minusPnOffset,
            onReplay: logic.resetPnOffset,
            onNext: logic.plusPnOffset,
          );
          if (callback != null && withVideo != null && withVideo == false) {
            callback(bar);
          }
          return bar;
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
          return null;
        }
      case ContentType.answerMedia:
        if (segment.mediaDocPath != "" && segment.aMediaSegments.isNotEmpty) {
          var bar = PlayerBar(
            state.answerMediaId,
            segment.segmentIndex,
            segment.aMediaSegments,
            segment.mediaDocPath,
            withVideo: withVideo ?? false,
            key: state.answerMediaKey,
            onFullScreen: logic.onMediaFullScreen,
            onInited: logic.onMediaInited,
          );
          if (callback != null && withVideo != null && withVideo == false) {
            callback(bar);
          }
          return bar;
        }
        return null;
      case ContentType.answerMediaPnc:
        if (segment.mediaDocPath != "" && segment.aMediaSegments.isNotEmpty) {
          var left = 0;
          var right = 0;
          var curr = -1;
          List<MediaSegment> segments = [];
          for (var i = -left; i <= right; i++) {
            var index = segment.segmentIndex + i;
            if (index >= 0 && index < segment.aMediaSegments.length) {
              segments.add(segment.aMediaSegments[index]);
              if (i == 0) {
                curr = segments.length - 1;
              }
            }
          }
          if (curr == -1) {
            return null;
          }
          var bar = PlayerBar(
            state.answerMediaId,
            curr,
            segments,
            segment.mediaDocPath,
            withVideo: withVideo ?? false,
            key: state.answerMediaKey,
            onFullScreen: logic.onMediaFullScreen,
            onInited: logic.onMediaInited,
            onPrevious: logic.minusPnOffset,
            onReplay: logic.resetPnOffset,
            onNext: logic.plusPnOffset,
          );
          if (callback != null && withVideo != null && withVideo == false) {
            callback(bar);
          }
          return bar;
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

  static Widget buildMediaController(GsCrRepeatLogic logic, GlobalKey<PlayerBarState> p) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.replay),
          iconSize: 20,
          onPressed: logic.resetPnOffset,
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 20,
          onPressed: logic.minusPnOffset,
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 20,
          onPressed: logic.plusPnOffset,
        ),
      ],
    );
  }

  static Widget buildBottom(GsCrRepeatLogic logic, double width) {
    var state = logic.state;
    var leftButtonText = "";
    var rightButtonText = "";
    void Function() leftButtonLogic = () => {};
    void Function()? leftButtonLongPressLogic;
    void Function() rightButtonLogic = () => {};
    void Function()? rightButtonLongPressLogic;
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
          rightButtonLogic = logic.tipLongPress;
          rightButtonLongPressLogic = logic.error;
          break;
        case RepeatStep.evaluate:
          leftButtonText = "${I18nKey.btnNext.tr}\n${state.nextKey}";
          leftButtonLogic = () => logic.know(autoNext: true);
          leftButtonLongPressLogic = logic.adjustProgress;
          rightButtonText = I18nKey.btnError.tr;
          rightButtonLogic = logic.tipLongPress;
          rightButtonLongPressLogic = logic.error;
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
            buildButton(
              leftButtonText,
              leftButtonLogic,
              width: width,
              onLongPress: leftButtonLongPressLogic,
            ),
            const Spacer(),
            buildButton(
              rightButtonText,
              rightButtonLogic,
              width: width,
              onLongPress: rightButtonLongPressLogic,
            ),
          ],
        ),
        if (!state.openTip)
          Row(
            children: [
              const Spacer(),
              buildButton(I18nKey.btnTips.tr, () => logic.tip(), width: width),
              const Spacer(),
            ],
          )
      ],
    );
  }

  static Widget buildButton(
    String text,
    VoidCallback onTap, {
    double height = 60,
    double? width,
    VoidCallback? onLongPress,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        child: Text(text),
      ),
    );
  }
}
