import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/widget/audio/media_bar.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:video_player/video_player.dart';

import 'model_media_range.dart';
import 'constant.dart';
import 'helper.dart';
import 'model_video_board.dart';
import 'repeat_view.dart';
import 'dart:io';

class RepeatViewForVideo extends RepeatView {
  static const String playerId = "RepeatViewForVideo";
  final GlobalKey<MediaBarState> mediaKey = GlobalKey<MediaBarState>();
  VideoPlayerController? _videoPlayerController;
  int duration = 0;
  late MediaRangeHelper mediaRangeHelper;
  late VideoBoardHelper videoBoardHelper;
  var initialized = false.obs;
  final bus = EventBus();
  late StreamSubscription<bool?> sub;

  // UI
  var showLandscapeOperateUi = true.obs;
  RxDouble videoHeightInPortrait = RxDouble(0);
  double mediaBarHeight = 50;
  double padding = 16;

  RepeatViewForVideo();

  VideoPlayerController get videoPlayerController {
    if (_videoPlayerController == null) {
      throw Exception("VideoPlayerController not initialized");
    }
    return _videoPlayerController!;
  }

  @override
  void init(Helper helper) {
    this.helper = helper;
    mediaRangeHelper = MediaRangeHelper(helper: helper);
    videoBoardHelper = VideoBoardHelper(helper: helper);
    sub = bus.on<bool>(EventTopic.setInRepeatView).listen((b) {
      mediaKey.currentState?.stop();
    });
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
  }

  @override
  Widget body() {
    Helper? helper = this.helper;
    if (helper == null) {
      return emptyBody();
    }

    var path = '';
    List<String>? paths = helper.getChapterPaths();
    if (paths != null && paths.isNotEmpty) {
      path = paths.first;
    }

    MediaRange? range;
    if (helper.step != RepeatStep.recall) {
      range = mediaRangeHelper.getCurrAnswerRange();
    }
    if (range == null || !range.enable) {
      range = mediaRangeHelper.getCurrQuestionRange();
    }

    if (range == null) {
      return emptyBody();
    }
    if (helper.enableReloadMedia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        load(path).then((_) {
          if (helper.withoutPlayingMediaFirstTime) {
            helper.withoutPlayingMediaFirstTime = false;
            return;
          }
          mediaKey.currentState?.playFromStart();
        });
      });
    }
    videoBoardHelper.boards.value = videoBoardHelper.getCurrVideoBoard();
    if (helper.landscape) {
      return landscape(range);
    } else {
      return portrait(range);
    }
  }

  emptyBody() {
    return Column(
      children: [
        const SizedBox(height: 50),
        if (helper != null) helper!.topBar(),
      ],
    );
  }

  landscape(MediaRange range) {
    var helper = this.helper!;
    var q = helper.text(QaType.question);
    var t = helper.edit || helper.tip == TipLevel.tip ? helper.text(QaType.tip) : null;
    var a = helper.edit || helper.step != RepeatStep.recall ? helper.text(QaType.answer) : null;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        GestureDetector(
          onTap: () {
            showLandscapeOperateUi.value = !showLandscapeOperateUi.value;
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              SizedBox(
                width: helper.screenWidth,
                height: helper.screenHeight,
              ),
              Obx(() => videoWidgetForLandscape()),
            ],
          ),
        ),
        Obx(
          () => AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            right: showLandscapeOperateUi.value ? 0 : -helper.screenWidth / 2,
            child: Container(
              color: Theme.of(Get.context!).colorScheme.onSecondary,
              height: helper.screenHeight,
              width: helper.screenWidth / 2,
              child: Column(
                children: [
                  SizedBox(height: helper.topBarHeight),
                  mediaBar(helper.screenWidth / 2, mediaBarHeight, range),
                  if (!videoBoardHelper.showEdit)
                    SizedBox(
                      height: helper.screenHeight - helper.topBarHeight - helper.bottomBarHeight - mediaBarHeight,
                      width: helper.screenWidth / 2,
                      child: Padding(
                        padding: EdgeInsets.only(left: padding, right: helper.leftPadding),
                        child: ListView(
                          padding: const EdgeInsets.all(0),
                          children: [
                            if (q != null) q,
                            if (t != null) t,
                            if (a != null) a,
                          ],
                        ),
                      ),
                    ),
                  if (videoBoardHelper.showEdit)
                    SizedBox(
                      height: helper.screenHeight - helper.topBarHeight - mediaBarHeight,
                      width: helper.screenWidth / 2,
                      child: Padding(
                        padding: EdgeInsets.only(left: padding, right: helper.leftPadding),
                        child: videoBoardHelper.editPanel(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        helper.topBar(),
        Obx(
          () => AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            bottom: showLandscapeOperateUi.value ? 0 : -helper.bottomBarHeight * 2,
            left: helper.screenWidth / 2,
            right: 0,
            child: videoBoardHelper.showEdit ? const SizedBox.shrink() : helper.bottomBar(width: helper.screenWidth / 2),
          ),
        ),
      ],
    );
  }

  portrait(MediaRange range) {
    var helper = this.helper!;
    double height = helper.screenHeight - helper.topPadding - helper.topBarHeight - mediaBarHeight - helper.bottomBarHeight;
    var q = helper.text(QaType.question);
    var t = helper.edit || helper.tip == TipLevel.tip ? helper.text(QaType.tip) : null;
    var a = helper.edit || helper.step != RepeatStep.recall ? helper.text(QaType.answer) : null;
    videoHeightInPortrait.value = videoWidgetHeight(height - helper.bottomBarHeight * 3);
    var bar = mediaBar(helper.screenWidth - padding * 2, mediaBarHeight, range);
    return Obx(() {
      return Column(
        children: [
          SizedBox(height: helper.topPadding),
          helper.topBar(),
          videoWidget(height - helper.bottomBarHeight * 3),
          bar,
          if (!videoBoardHelper.showEdit)
            SizedBox(
              height: height - videoHeightInPortrait.value,
              child: Padding(
                padding: EdgeInsets.fromLTRB(padding, 0, padding, 0),
                child: ListView(
                  padding: const EdgeInsets.all(0),
                  children: [
                    if (q != null) q,
                    if (t != null) t,
                    if (a != null) a,
                  ],
                ),
              ),
            ),
          if (videoBoardHelper.showEdit)
            SizedBox(
              height: height - videoHeightInPortrait.value,
              child: Padding(
                padding: EdgeInsets.fromLTRB(padding, 0, padding, 0),
                child: videoBoardHelper.editPanel(),
              ),
            ),
          if (!videoBoardHelper.showEdit) helper.bottomBar(width: helper.screenWidth),
        ],
      );
    });
  }

  Widget videoWidgetForLandscape() {
    final videoPrepared = _videoPlayerController != null && _videoPlayerController!.value.isInitialized;
    final isInitialized = initialized.value && videoPrepared;

    if (!isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final aspectRatio = _videoPlayerController!.value.aspectRatio;
    final screenWidth = helper!.screenWidth;
    final screenHeight = helper!.screenHeight;

    double targetWidth, targetHeight, left, right, top, bottom;

    if (showLandscapeOperateUi.value) {
      final maxWidth = screenWidth / 2;

      targetHeight = screenHeight;
      targetWidth = targetHeight * aspectRatio;

      if (targetWidth > maxWidth) {
        targetWidth = maxWidth;
        targetHeight = targetWidth / aspectRatio;
        final verticalPadding = (screenHeight - targetHeight) / 2;
        top = verticalPadding;
        bottom = verticalPadding;
        left = 0;
        right = maxWidth;
      } else {
        final horizontalPadding = (maxWidth - targetWidth) / 2;
        top = 0;
        bottom = 0;
        left = horizontalPadding;
        right = horizontalPadding + maxWidth;
      }
    } else {
      targetHeight = screenHeight;
      targetWidth = targetHeight * aspectRatio;

      if (targetWidth > screenWidth) {
        targetWidth = screenWidth;
        targetHeight = targetWidth / aspectRatio;
        final verticalPadding = (screenHeight - targetHeight) / 2;
        top = verticalPadding;
        bottom = verticalPadding;
        left = 0;
        right = 0;
      } else {
        final horizontalPadding = (screenWidth - targetWidth) / 2;
        top = 0;
        bottom = 0;
        left = horizontalPadding;
        right = horizontalPadding;
      }
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 150),
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: videoBoardHelper.wrapVideo(
        width: targetWidth,
        height: targetHeight,
        video: VideoPlayer(_videoPlayerController!),
        onPressed: () {
          videoBoardHelper.openedVideoBoardSettings.value = true;
        },
      ),
    );
  }

  double videoWidgetHeight(double maxHeight) {
    final controller = _videoPlayerController;
    final isVideoReady = controller != null && controller.value.isInitialized;

    if (!(initialized.value && isVideoReady)) {
      return 300;
    }

    final aspectRatio = controller.value.aspectRatio;
    final screenWidth = helper!.screenWidth;

    double width = maxHeight * aspectRatio;
    if (width < screenWidth) {
      return maxHeight;
    } else {
      return screenWidth / aspectRatio;
    }
  }

  Widget videoWidget(double maxHeight) {
    final controller = _videoPlayerController;
    final isVideoReady = controller != null && controller.value.isInitialized;

    if (!(initialized.value && isVideoReady)) {
      return const Center(child: CircularProgressIndicator());
    }

    final aspectRatio = controller.value.aspectRatio;
    final screenWidth = helper!.screenWidth;
    void onPressed() {
      videoBoardHelper.openedVideoBoardSettings.value = true;
    }

    double width = maxHeight * aspectRatio;
    if (width < screenWidth) {
      videoHeightInPortrait.value = maxHeight;
      return Center(
        child: videoBoardHelper.wrapVideo(
          width: width,
          height: maxHeight,
          video: VideoPlayer(_videoPlayerController!),
          onPressed: onPressed,
        ),
      );
    } else {
      double height = screenWidth / aspectRatio;
      videoHeightInPortrait.value = height;
      return videoBoardHelper.wrapVideo(
        width: screenWidth,
        height: height,
        video: VideoPlayer(_videoPlayerController!),
        onPressed: onPressed,
      );
    }
  }

  Widget mediaBar(double width, double height, MediaRange range) {
    return MediaBar(
      width: width,
      height: height,
      verseStartMs: range.start,
      verseEndMs: range.end,
      key: mediaKey,
      duration: () => duration,
      onPlay: (Duration position) async {
        if (_videoPlayerController != null) {
          try {
            await _videoPlayerController!.seekTo(position).timeout(const Duration(milliseconds: 100));
          } catch (e) {
            await _videoPlayerController!.initialize();
            await _videoPlayerController!.seekTo(position);
          }
          await _videoPlayerController!.play();
        }
      },
      onStop: () async {
        if (_videoPlayerController != null) {
          await _videoPlayerController!.pause();
        }
      },
      onEdit: mediaRangeHelper.mediaRangeEdit(range),
      onAdjustSpeed: (double speed) async {
        await _videoPlayerController?.setPlaybackSpeed(speed);
      },
      getSpeed: () {
        return _videoPlayerController?.value.playbackSpeed ?? 1;
      },
      hideTime: helper!.concentrationMode,
    );
  }

  Future<void> load(String path) async {
    try {
      var helper = this.helper!;
      var ok = await helper.tryImportMedia(
        localMediaPath: path,
        allowedExtensions: ['mp4'],
      );
      if (!ok) {
        return;
      }
      bool needsInitialization = true;

      if (_videoPlayerController != null) {
        final uri = Uri.parse(_videoPlayerController!.dataSource);
        if (uri.toFilePath() == path) {
          needsInitialization = false;
        } else {
          initialized.value = false;
          await _videoPlayerController!.dispose();
        }
      }

      if (needsInitialization) {
        try {
          _videoPlayerController = VideoPlayerController.file(File(path));
          await _videoPlayerController!.initialize();
        } catch (e) {
          var ok = await helper.tryImportMedia(
            localMediaPath: path,
            allowedExtensions: ['mp4'],
          );
          if (!ok) {
            return;
          }
        }

        if (_videoPlayerController!.value.isInitialized) {
          duration = _videoPlayerController!.value.duration.inMilliseconds;
        }
        initialized.value = true;
      }
    } catch (e) {
      Snackbar.show("Error loading video: $e");
    }
  }
}
