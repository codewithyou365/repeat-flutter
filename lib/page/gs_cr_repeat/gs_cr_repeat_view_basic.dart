import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';
import 'package:repeat_flutter/widget/player_bar/video_mask.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'gs_cr_repeat_logic.dart';
import 'gs_cr_repeat_state.dart';

typedef HideVideoPlayerBarCallback = void Function(PlayerBar playerBar);

class GsCrRepeatViewBasic {
  static Widget titleWidget(GsCrRepeatLogic logic, double? fontSize) {
    var state = logic.state;
    var currIndex = 0;
    if (state.justView) {
      currIndex = state.justViewIndex + 1;
    } else {
      currIndex = state.progress + state.fakeKnow;
    }
    String prefix = '$currIndex/${state.total}-';
    if (state.concentrationMode) {
      prefix = '';
    }
    return Text(
      "$prefix${state.segment.k}",
      style: fontSize == null ? null : TextStyle(fontSize: fontSize),
    );
  }

  static Widget buildContent(BuildContext context, GsCrRepeatLogic logic, {bool? left, Widget? firstChild, double? padding}) {
    var state = logic.state;
    state.step.index;
    var showContent = logic.getShowContent();
    List<Widget> listViewContent = [];
    if (firstChild != null) {
      listViewContent.add(firstChild);
    }
    for (int i = 0; i < showContent.length; i++) {
      Widget? w;
      if (left != null) {
        if (left == showContent[i].left) {
          w = GsCrRepeatViewBasic.buildInnerContent(context, showContent[i].contentType, state.segment, state.gameMode);
        }
      } else {
        w = GsCrRepeatViewBasic.buildInnerContent(context, showContent[i].contentType, state.segment, state.gameMode);
      }
      Widget? addWidget;
      if (w != null) {
        var tip = showContent[i].tip ?? false;
        if (tip && state.openTip) {
          addWidget = w;
        } else if (!tip) {
          addWidget = w;
        }
      }
      if (addWidget != null && padding != null) {
        listViewContent.add(Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: addWidget,
        ));
      } else if (addWidget != null) {
        listViewContent.add(addWidget);
      }
    }

    return ListView(padding: const EdgeInsets.all(0), children: listViewContent);
  }

  static PlayerBar? getPlayerBar(GsCrRepeatLogic logic, double width, double height, double? maskHeight) {
    GsCrRepeatState state = logic.state;
    VoidCallback? onPrevious;
    VoidCallback? onNext;
    if (state.step != RepeatStep.recall) {
      onPrevious = logic.minusPnOffset;
      onNext = logic.plusPnOffset;
    }
    double maskRatio = 0;
    SetMaskRatioCallback? setMaskRatio;
    if (maskHeight == null) {
      setMaskRatio = logic.setMaskRatio;
      maskRatio = logic.getMaskRatio();
    }
    if (state.segment.mediaExtension != "") {
      return PlayerBar(
        GsCrRepeatState.mediaId,
        0,
        width,
        height,
        logic.getSegments(),
        state.segment.mediaDocPath,
        withVideo: false,
        key: state.mediaKey,
        initMaskHeight: maskHeight ?? 0,
        initMaskRatio: maskRatio,
        setMaskRatio: setMaskRatio,
        onPrevious: onPrevious,
        onReplay: logic.resetPnOffset,
        onNext: onNext,
      );
    }
    return null;
  }

  static Widget? buildInnerContent(BuildContext context, ContentType t, SegmentContent segment, bool gameMode) {
    switch (t) {
      case ContentType.question:
        if (segment.question != "") {
          return Text(segment.question);
        } else {
          return null;
        }
      case ContentType.answer:
        if (segment.answer != "") {
          return Text(segment.answer);
        } else {
          return null;
        }
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

  static Widget buildBottom(GsCrRepeatLogic logic, double width, double height) {
    var state = logic.state;
    var leftButtonText = "";
    var rightButtonText = "";
    void Function() leftButtonLogic = () => {};
    void Function()? leftButtonLongPressLogic;
    void Function() rightButtonLogic = () => {};
    void Function()? rightButtonLongPressLogic;
    if (state.justView || state.edit) {
      switch (state.step) {
        case RepeatStep.recall:
          leftButtonText = I18nKey.btnShow.tr;
          leftButtonLogic = logic.showForJustView;
          rightButtonText = I18nKey.btnPrevious.tr;
          rightButtonLogic = logic.previousForJustView;
          break;
        case RepeatStep.evaluate:
          var tryFinish = false;
          if (state.c.length == state.justViewIndex + 1) {
            tryFinish = true;
            leftButtonText = I18nKey.btnFinish.tr;
          } else if (state.nextKey == "") {
            leftButtonText = I18nKey.btnNext.tr;
          } else {
            leftButtonText = "${I18nKey.btnNext.tr}\n${state.nextKey}";
          }
          leftButtonLogic = () => logic.nextForJustView(tryFinish: tryFinish);
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
          var tryFinish = false;
          if (state.c.length == 1) {
            tryFinish = true;
            leftButtonText = I18nKey.btnFinish.tr;
          } else if (state.nextKey == "") {
            leftButtonText = I18nKey.btnNext.tr;
          } else {
            leftButtonText = "${I18nKey.btnNext.tr}\n${state.nextKey}";
          }
          leftButtonLogic = () => logic.know(autoNext: true, tryFinish: tryFinish);
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
            if (state.nextKey == "") {
              leftButtonText = I18nKey.btnNext.tr;
            } else {
              leftButtonText = "${I18nKey.btnNext.tr}\n${state.nextKey}";
            }
            leftButtonLogic = logic.next;
          }
          break;
      }
    }
    var buttonWidth = width / 2;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Row(
            children: [
              buildButton(
                leftButtonText,
                logic.onPreClick,
                leftButtonLogic,
                width: buttonWidth,
                onLongPress: leftButtonLongPressLogic,
              ),
              const Spacer(),
              buildButton(
                rightButtonText,
                logic.onPreClick,
                rightButtonLogic,
                width: buttonWidth,
                onLongPress: rightButtonLongPressLogic,
              ),
            ],
          ),
          if (!state.openTip)
            Row(
              children: [
                const Spacer(),
                buildButton(
                  I18nKey.btnTips.tr,
                  logic.onPreClick,
                  () => logic.tip(),
                  width: buttonWidth,
                ),
                const Spacer(),
              ],
            )
        ],
      ),
    );
  }

  static Widget buildButton(
    String text,
    VoidCallback onPreClick,
    VoidCallback onTap, {
    double height = 60,
    double? width,
    VoidCallback? onLongPress,
  }) {
    return InkWell(
      onTap: () {
        onPreClick();
        onTap();
      },
      onLongPress: () {
        onPreClick();
        if (onLongPress != null) {
          onLongPress();
        }
      },
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        child: Text(text),
      ),
    );
  }

  static void showGameAddress(BuildContext context, GsCrRepeatLogic logic) {
    final Size screenSize = MediaQuery.of(context).size;
    var state = logic.state;
    List<String> address = state.gameAddress;
    int id = state.segmentTodayPrg.id!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SizedBox(
          width: screenSize.width,
          height: screenSize.height / 2,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 20.0),
            child: ListView(
              children: [
                RowWidget.buildText(
                  I18nKey.labelGameId.tr,
                  "$id",
                ),
                const Divider(color: Colors.grey),
                RowWidget.buildSwitch(
                  I18nKey.labelIgnorePunctuation.tr,
                  state.ignoringPunctuation,
                  logic.setIgnoringPunctuation,
                ),
                const Divider(color: Colors.grey),
                RowWidget.buildSwitch(
                  I18nKey.labelEditInGame.tr,
                  state.editInGame,
                ),
                const Divider(color: Colors.grey),
                ...List.generate(
                  address.length,
                  (index) => Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Card(
                      child: InkWell(
                        onTap: () => {
                          MsgBox.noWithQrCode(
                            I18nKey.labelLanAddress.tr,
                            address[index],
                            address[index],
                          )
                        },
                        child: ListTile(
                          title: Text('${I18nKey.labelLanAddress.tr}-${index + 1}'),
                          subtitle: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Text(address[index]),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
