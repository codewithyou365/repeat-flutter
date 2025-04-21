import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';

import 'gs_cr_repeat_logic.dart';
import 'logic/constant.dart';

class GsCrRepeatPage extends StatelessWidget {
  const GsCrRepeatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GsCrRepeatLogic>(
      id: GsCrRepeatLogic.id,
      builder: (_) {
        return Scaffold(
          body: buildCore(context),
        );
      },
    );
  }

  Widget buildCore(BuildContext context) {
    final logic = Get.find<GsCrRepeatLogic>();
    final state = logic.state;
    final Size screenSize = MediaQuery.of(context).size;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double leftPadding = MediaQuery.of(context).padding.left;
    final double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    var landscape = false;
    if (screenWidth > screenHeight) {
      landscape = true;
    }
    state.helper.screenWidth = screenWidth;
    state.helper.screenHeight = screenHeight;
    state.helper.landscape = landscape;
    state.helper.leftPadding = leftPadding;
    state.helper.topPadding = topPadding;
    double topBarHeight = state.helper.topBarHeight;
    state.helper.topBar = () => topBar(logic: logic, height: topBarHeight);
    state.helper.bottomBar = ({required double width}) => bottomBar(logic: logic, width: width, height: state.helper.bottomBarHeight);

    if (state.lastLandscape == null || state.lastLandscape != landscape) {
      state.lastLandscape = landscape;
      state.needUpdateSystemUiMode = true;
    }
    if (state.needUpdateSystemUiMode) {
      state.needUpdateSystemUiMode = false;
      if (landscape) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
      } else {
        if (state.concentrationMode) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
        } else {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
        }
      }
    }
    return logic.repeatView.body();
  }

  Widget topBar({required GsCrRepeatLogic logic, required double height}) {
    final repeatLogic = logic.repeatLogic;
    final state = logic.state;
    return Stack(
      alignment: Alignment.center,
      children: [
        topBarTitle(logic: logic, fontSize: 18),
        SizedBox(
          height: height,
          child: Row(
            children: [
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  Nav.back();
                },
              ),
              const Spacer(),
              if (repeatLogic != null && repeatLogic.step != RepeatStep.recall)
                IconButton(
                  icon: const Icon(Icons.assistant_photo),
                  onPressed: logic.adjustProgress,
                ),
              if (repeatLogic != null && repeatLogic.step != RepeatStep.recall)
                IconButton(
                  icon: const Icon(Icons.list_alt),
                  tooltip: I18nKey.labelDetail.tr,
                  onPressed: logic.openSegmentList,
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  // PopupMenuItem<String>(
                  //   onTap: () => logic.openGameMode(context),
                  //   child: Text("${I18nKey.btnGameMode.tr}(${state.gameMode})"),
                  // ),
                  PopupMenuItem<String>(
                    onTap: logic.switchConcentrationMode,
                    child: Text("${I18nKey.btnConcentration.tr}(${state.concentrationMode})"),
                  ),
                  // PopupMenuItem<String>(
                  //   onTap: logic.extendTail,
                  //   child: Text("${I18nKey.btnExtendTail.tr}(${state.extendTail})"),
                  // ),
                  // PopupMenuItem<String>(
                  //   onTap: logic.resetTail,
                  //   child: Text(I18nKey.btnResetTail.tr),
                  // ),
                ],
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget topBarTitle({required GsCrRepeatLogic logic, double? fontSize}) {
    var state = logic.state;
    String text = '';
    if (!state.concentrationMode && logic.repeatLogic != null) {
      text = logic.repeatLogic!.titleLabel;
    }
    return Text(
      text,
      style: fontSize == null ? null : TextStyle(fontSize: fontSize),
    );
  }

  Widget bottomBar({required GsCrRepeatLogic logic, required double width, required double height}) {
    var repeatLogic = logic.repeatLogic;
    var leftButtonText = repeatLogic?.leftLabel ?? '';
    var rightButtonText = repeatLogic?.rightLabel ?? '';
    void Function() leftButtonLogic = repeatLogic?.onTapLeft ?? () {};
    void Function() rightButtonLogic = repeatLogic?.onTapRight ?? () {};
    void Function()? rightButtonLongPressLogic = repeatLogic?.getLongTapRight();
    var buttonWidth = width / 2;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Row(
            children: [
              bottomBarButton(
                leftButtonText,
                logic.onPreClick,
                leftButtonLogic,
                width: buttonWidth,
              ),
              const Spacer(),
              bottomBarButton(
                rightButtonText,
                logic.onPreClick,
                rightButtonLogic,
                width: buttonWidth,
                onLongPress: rightButtonLongPressLogic,
              ),
            ],
          ),
          Row(
            children: [
              const Spacer(),
              bottomBarButton(
                I18nKey.btnTips.tr,
                logic.onPreClick,
                () {},
                width: buttonWidth,
                //onLongPress: logic.tipWithAnswer,
              ),
              const Spacer(),
            ],
          )
        ],
      ),
    );
  }

  Widget bottomBarButton(
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
}
