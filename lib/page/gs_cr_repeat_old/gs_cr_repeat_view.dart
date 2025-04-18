import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/repeat_doc_edit_help.dart';
import 'package:repeat_flutter/logic/repeat_doc_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/player_bar/media.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

import 'gs_cr_repeat_logic.dart';
import 'gs_cr_repeat_state.dart';
import 'gs_cr_repeat_view_basic.dart';

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
    final Size screenSize = MediaQuery.of(context).size;
    final double top = MediaQuery.of(context).padding.top;
    final double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    var landscape = false;
    if (screenWidth > screenHeight) {
      landscape = true;
    }
    if (logic.state.lastLandscape == null || logic.state.lastLandscape != landscape) {
      logic.state.lastLandscape = landscape;
      logic.state.needUpdateSystemUiMode = true;
    }
    if (logic.state.needUpdateSystemUiMode) {
      logic.state.needUpdateSystemUiMode = false;
      if (landscape) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
      } else {
        if (logic.state.concentrationMode) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
        } else {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
        }
      }
    }

    final state = logic.state;
    double widgetBottomHeight = 50;
    const double verticalWidth = 10;
    double padding = 20;
    double sideWidth = landscape ? (screenWidth / 2) - verticalWidth / 2 - padding : screenWidth - padding * 2;

    double topBarHeight = 50;

    double? maskHeight;
    double spaceBottomHeight = 200;
    if (landscape) {
      var screenRatio = screenWidth / screenHeight;
      double videoAspectRatio = state.mediaKey.currentState?.getVideoAspectRatio() ?? 0.0;
      if (screenRatio > videoAspectRatio && videoAspectRatio > 0) {
        double videoHeight = screenHeight;
        var segment = state.currSegment;
        var videoMaskHeight = 0.0;//TODO videoHeight / RepeatDocHelp.getVideoMaskRatio(segment.contentSerial, segment.lessonIndex, segment.mediaExtension);
        if (videoMaskHeight < spaceBottomHeight) {
          if (logic.getMaskRatio() > 0) {
            maskHeight = videoMaskHeight;
          }
          spaceBottomHeight = videoMaskHeight;
        }
      }
    }

    PlayerBar? playerBar = GsCrRepeatViewBasic.getPlayerBar(logic, landscape ? sideWidth : screenWidth, widgetBottomHeight, maskHeight);

    double totalBottomHeight;
    if (landscape) {
      totalBottomHeight = widgetBottomHeight;
    } else {
      totalBottomHeight = widgetBottomHeight;
      if (playerBar != null) {
        totalBottomHeight += widgetBottomHeight;
      }
    }
    if (state.edit) {
      totalBottomHeight += widgetBottomHeight;
    }

    if (landscape) {
      totalBottomHeight += spaceBottomHeight;
    }
    double bodyHeight = screenHeight - topBarHeight - totalBottomHeight;
    if (!landscape) {
      bodyHeight -= top;
    }

    if (playerBar != null && playerBar.playerId == GsCrRepeatState.mediaId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        logic.mediaLoad((String playerId) {
          if (logic.onMediaInited(playerId) && Media.isVideo(playerBar.path)) {
            state.videoKey.currentState?.refresh();
          }
        });
      });
    }

    var buildTopVideoView = false;
    var buildListVideoView = false;
    if (playerBar != null) {
      if (landscape) {
        buildTopVideoView = true;
      } else {
        if (state.overlayVideoInPortrait) {
          buildTopVideoView = true;
        } else {
          buildListVideoView = true;
        }
      }
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        if (buildTopVideoView) buildTop(Media.mediaView(playerBar!, key: state.videoKey), topBarHeight, top, landscape),
        Column(children: [
          if (!landscape) SizedBox(height: top),
          Stack(
            alignment: Alignment.center,
            children: [
              GsCrRepeatViewBasic.titleWidget(logic, 18),
              SizedBox(
                height: topBarHeight,
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
                    if (state.step == RepeatStep.evaluate)
                      IconButton(
                        icon: const Icon(Icons.assistant_photo),
                        onPressed: logic.adjustProgress,
                      ),
                    if (state.step == RepeatStep.evaluate)
                      IconButton(
                        icon: const Icon(Icons.list_alt),
                        tooltip: I18nKey.labelDetail.tr,
                        onPressed: logic.openSegmentList,
                      ),
                    if (state.edit == false)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            onTap: () => logic.openGameMode(context),
                            child: Text("${I18nKey.btnGameMode.tr}(${state.gameMode})"),
                          ),
                          if (!state.gameMode)
                            PopupMenuItem<String>(
                              onTap: logic.openEditor,
                              child: Text(I18nKey.btnEditTrack.tr),
                            ),
                          PopupMenuItem<String>(
                            onTap: logic.switchConcentrationMode,
                            child: Text("${I18nKey.btnConcentration.tr}(${state.concentrationMode})"),
                          ),
                          PopupMenuItem<String>(
                            onTap: logic.extendTail,
                            child: Text("${I18nKey.btnExtendTail.tr}(${state.extendTail})"),
                          ),
                          PopupMenuItem<String>(
                            onTap: logic.resetTail,
                            child: Text(I18nKey.btnResetTail.tr),
                          ),
                        ],
                      ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ],
          ),
          buildBody(
            context,
            logic,
            verticalWidth,
            padding,
            landscape,
            sideWidth,
            bodyHeight,
            firstChild: buildListVideoView ? Media.mediaView(playerBar!, key: state.videoKey) : null,
          ),
          SizedBox(
            height: totalBottomHeight,
            child: buildBottom(
              state.edit ? buildEditorBottom(logic, screenWidth, widgetBottomHeight) : null,
              playerBar,
              GsCrRepeatViewBasic.buildBottom(logic, sideWidth, widgetBottomHeight),
              verticalWidth,
              sideWidth,
              landscape,
              spaceBottomHeight,
            ),
          ),
        ])
      ],
    );
  }

  Widget buildTop(Widget video, double top, double appBarHeight, bool landscape) {
    if (landscape) {
      return video;
    } else {
      return Column(children: [
        SizedBox(
          height: top + appBarHeight,
        ),
        video,
      ]);
    }
  }

  Widget buildBottom(Widget? editorBottom, PlayerBar? playerBar, Widget bottom, double verticalWidth, double sideWidth, bool landscape, double spaceBottomHeight) {
    if (landscape) {
      return Column(
        children: [
          Container(
            color: Theme.of(Get.context!).brightness == Brightness.dark ? const Color(0x50000000) : const Color(0x50FFFFFF),
            child: Column(
              children: [
                if (editorBottom != null) editorBottom,
                Row(
                  children: [
                    if (playerBar != null) playerBar,
                    playerBar != null ? SizedBox(width: verticalWidth) : SizedBox(width: sideWidth + verticalWidth),
                    bottom,
                  ],
                )
              ],
            ),
          ),
          SizedBox(height: spaceBottomHeight),
        ],
      );
    } else {
      return Column(
        children: [
          if (editorBottom != null) editorBottom,
          if (playerBar != null) playerBar,
          bottom,
        ],
      );
    }
  }

  Widget buildEditorBottom(GsCrRepeatLogic logic, double width, double height) {
    double buttonWidth = (width - 20) / 2;
    return SizedBox(
      width: width,
      height: height,
      child: Row(
        children: [
          PopupMenuButton<String>(
            child: Container(
              width: buttonWidth,
              height: height,
              alignment: Alignment.center,
              child: Text(I18nKey.btnSet.tr),
            ),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                onTap: () {
                  logic.edit(EditType.setHead);
                },
                child: Text(I18nKey.btnSetHead.tr),
              ),
              PopupMenuItem<String>(
                onTap: () {
                  logic.edit(EditType.setTail);
                },
                child: Text(I18nKey.btnSetTail.tr),
              ),
              PopupMenuItem<String>(
                onTap: () {
                  logic.edit(EditType.extendTail);
                },
                child: Text(I18nKey.btnExtendTail.tr),
              ),
            ],
          ),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            child: Container(
              width: buttonWidth,
              height: height,
              alignment: Alignment.center,
              child: Text(I18nKey.btnOther.tr),
            ),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                onTap: () {
                  logic.edit(EditType.cut);
                },
                child: Text(I18nKey.btnCut.tr),
              ),
              PopupMenuItem<String>(
                onTap: () {
                  logic.edit(EditType.deleteCurr);
                },
                child: Text(I18nKey.btnDeleteCurr.tr),
              ),
              PopupMenuItem<String>(
                onTap: logic.editQa,
                child: Text(I18nKey.btnEditSegment.tr),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildBody(BuildContext context, GsCrRepeatLogic logic, double verticalWidth, double padding, bool landscape, double sideWidth, double height, {Widget? firstChild}) {
    return SizedBox(
      height: height,
      child: landscape
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Row(
                children: [
                  SizedBox(
                    width: sideWidth,
                    child: GsCrRepeatViewBasic.buildContent(context, logic, left: true),
                  ),
                  SizedBox(
                    width: verticalWidth,
                  ),
                  SizedBox(
                    width: sideWidth,
                    child: GsCrRepeatViewBasic.buildContent(context, logic, left: false),
                  ),
                ],
              ),
            )
          : GsCrRepeatViewBasic.buildContent(context, logic, firstChild: firstChild, padding: padding),
    );
  }
}
