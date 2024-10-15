import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    final state = logic.state;
    double widgetBottomHeight = 50;
    const double verticalWidth = 10;
    double padding = 20;
    double sideWidth = landscape ? (screenWidth / 2) - verticalWidth / 2 - padding : screenWidth - padding * 2;

    PlayerBar? playerBar = GsCrRepeatViewBasic.getPlayerBar(logic, landscape ? sideWidth : screenWidth, widgetBottomHeight);
    double appBarHeight = 50;
    double totalBottomHeight;
    if (landscape) {
      totalBottomHeight = 50;
    } else {
      if (playerBar == null) {
        totalBottomHeight = 50;
      } else {
        totalBottomHeight = 100;
      }
    }
    double bodyHeight = screenHeight - appBarHeight - totalBottomHeight;
    if (!landscape) {
      bodyHeight -= top;
    }

    if (playerBar != null && playerBar.playerId == GsCrRepeatState.mediaId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        logic.mediaLoad((String playerId) {
          logic.onMediaInited(playerId);
          if (Media.isVideo(playerBar.path)) {
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
        if (buildTopVideoView) buildTop(Media.mediaView(playerBar!, key: state.videoKey), appBarHeight, top, landscape),
        Column(children: [
          if (!landscape) SizedBox(height: top),
          Stack(
            alignment: Alignment.center,
            children: [
              GsCrRepeatViewBasic.titleWidget(logic, 18),
              SizedBox(
                height: appBarHeight,
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
              playerBar,
              GsCrRepeatViewBasic.buildBottom(logic, sideWidth, widgetBottomHeight),
              verticalWidth,
              sideWidth,
              landscape,
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

  Widget buildBottom(PlayerBar? playerBar, Widget bottom, double verticalWidth, double sideWidth, bool landscape) {
    if (landscape) {
      return Container(
        color: Theme.of(Get.context!).brightness == Brightness.dark ? const Color(0x50000000) : const Color(0x50FFFFFF),
        child: Row(
          children: [
            if (playerBar != null) playerBar,
            playerBar != null ? SizedBox(width: verticalWidth) : SizedBox(width: sideWidth + verticalWidth),
            bottom,
          ],
        ),
      );
    } else {
      return Column(
        children: [
          if (playerBar != null) playerBar,
          bottom,
        ],
      );
    }
  }

  Widget buildBody(BuildContext context, GsCrRepeatLogic logic, double verticalWidth, double padding, bool landscape, double sideWidth, double height, {Widget? firstChild}) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: landscape
            ? Row(
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
              )
            : GsCrRepeatViewBasic.buildContent(context, logic, firstChild: firstChild),
      ),
    );
  }
}
