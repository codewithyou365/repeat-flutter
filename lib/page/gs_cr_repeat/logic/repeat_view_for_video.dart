import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/widget/audio/media_bar.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:video_player/video_player.dart';
import 'constant.dart';
import 'model.dart';
import 'helper.dart';
import 'repeat_view.dart';
import 'dart:io';

class RepeatViewForVideo extends RepeatView {
  static const String playerId = "RepeatViewForVideo";
  final GlobalKey<MediaBarState> mediaKey = GlobalKey<MediaBarState>();
  VideoPlayerController? _videoPlayerController;
  int duration = 0;
  late MediaSegmentHelper mediaSegmentHelper;
  var initialized = false.obs;

  // UI
  var showLandscapeUi = true.obs;
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
    mediaSegmentHelper = MediaSegmentHelper(helper: helper);
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
    var s = mediaSegmentHelper.getMediaSegment();
    if (s == null) {
      return emptyBody();
    }

    var path = '';
    List<String>? paths = helper.getPaths();
    if (paths != null && paths.isNotEmpty) {
      path = paths.first;
    }

    Range? range;
    if (path.isNotEmpty) {
      if (helper.step != RepeatStep.recall) {
        range = mediaSegmentHelper.getCurrAnswerRange();
      }
      if (range == null || !range.enable) {
        range = mediaSegmentHelper.getCurrQuestionRange();
      }
    }

    if (range == null || !range.enable) {
      return emptyBody();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      load(path).then((_) {
        mediaKey.currentState?.playFromStart();
      });
    });

    if (helper.landscape) {
      return landscape(s, range);
    } else {
      return portrait(s, range);
    }
  }

  emptyBody() {
    return Column(children: [
      const SizedBox(height: 50),
      if (helper != null) helper!.topBar(),
    ]);
  }

  landscape(MediaSegment s, Range range) {
    var helper = this.helper!;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        GestureDetector(
          onTap: () {
            showLandscapeUi.value = !showLandscapeUi.value;
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              SizedBox(
                width: helper.screenWidth,
                height: helper.screenHeight,
              ),
              Obx(() => videoWidgetForLandscape())
            ],
          ),
        ),
        Obx(
          () => AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            right: showLandscapeUi.value ? 0 : -helper.screenWidth / 2,
            child: Container(
              color: Theme.of(Get.context!).colorScheme.onSecondary,
              height: helper.screenHeight,
              width: helper.screenWidth / 2,
              child: Column(
                children: [
                  SizedBox(height: helper.topBarHeight),
                  SizedBox(
                    height: helper.screenHeight - helper.topBarHeight - helper.bottomBarHeight,
                    width: helper.screenWidth / 2,
                    child: Padding(
                      padding: EdgeInsets.only(left: padding, right: helper.leftPadding),
                      child: ListView(padding: const EdgeInsets.all(0), children: [
                        if (s.question != null && s.question!.isNotEmpty) Text(s.question!),
                        if (helper.step != RepeatStep.recall) Text(s.answer),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Obx(() => showLandscapeUi.value ? helper.topBar() : SizedBox(width: helper.screenWidth)),
        Obx(
          () => AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            bottom: showLandscapeUi.value ? 0 : -helper.bottomBarHeight,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white.withAlpha(200),
              child: Row(
                children: [
                  mediaBar(helper.screenWidth / 2, helper.bottomBarHeight, range),
                  helper.bottomBar(width: helper.screenWidth / 2),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  portrait(MediaSegment s, Range range) {
    var helper = this.helper!;
    double height = helper.screenHeight - helper.topPadding - helper.topBarHeight - helper.bottomBarHeight;
    var bar = mediaBar(helper.screenWidth - padding * 2, helper.bottomBarHeight, range);
    return Column(
      children: [
        SizedBox(height: helper.topPadding),
        helper.topBar(),
        SizedBox(
          height: height,
          child: ListView(padding: const EdgeInsets.all(0), children: [
            videoWidget(height - helper.bottomBarHeight * 3),
            Padding(
              padding: EdgeInsets.fromLTRB(padding, 0, padding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar,
                  if (s.question != null && s.question!.isNotEmpty) Text(s.question!),
                  if (helper.step != RepeatStep.recall) Text(s.answer),
                ],
              ),
            ),
          ]),
        ),
        helper.bottomBar(width: helper.screenWidth),
      ],
    );
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
    final topBar = helper!.topBarHeight;
    final bottomBar = helper!.bottomBarHeight;

    double targetWidth, targetHeight, left, right, top, bottom;

    if (showLandscapeUi.value) {
      final maxHeight = screenHeight - topBar - bottomBar;
      final maxWidth = screenWidth / 2;

      targetHeight = maxHeight;
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
        top = topBar;
        bottom = bottomBar;
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
      child: SizedBox(
        width: targetWidth,
        height: targetHeight,
        child: VideoPlayer(_videoPlayerController!),
      ),
    );
  }

  Widget videoWidget(double maxHeight) {
    return Obx(() {
      bool videoPrepared = _videoPlayerController != null && _videoPlayerController!.value.isInitialized;
      double aspectRatio = 16.0 / 9.0;
      if (videoPrepared) {
        aspectRatio = _videoPlayerController!.value.aspectRatio;
      }
      if (initialized.value && videoPrepared) {
        double width = maxHeight * aspectRatio;
        if (width < helper!.screenWidth) {
          var sb = SizedBox(
            width: width,
            height: maxHeight,
            child: VideoPlayer(_videoPlayerController!),
          );
          return Center(child: sb);
        }
        return AspectRatio(
          aspectRatio: aspectRatio,
          child: VideoPlayer(_videoPlayerController!),
        );
      } else {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    });
  }

  Widget mediaBar(double width, double height, Range range) {
    return MediaBar(
      width: width,
      height: height,
      segmentStartMs: range.start,
      segmentEndMs: range.end,
      key: mediaKey,
      duration: () => duration,
      onPlay: (Duration position) async {
        if (_videoPlayerController != null) {
          await _videoPlayerController!.seekTo(position);
          await _videoPlayerController!.play();
        }
      },
      onStop: () async {
        if (_videoPlayerController != null) {
          await _videoPlayerController!.pause();
        }
      },
    );
  }

  Future<void> load(String path) async {
    if (path.isEmpty) return;

    try {
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
        _videoPlayerController = VideoPlayerController.file(File(path));
        await _videoPlayerController!.initialize();

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
