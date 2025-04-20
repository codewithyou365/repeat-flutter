import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/widget/audio/media_bar.dart';
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
  Widget body({required double height}) {
    Helper? helper = this.helper;
    if (helper == null) {
      return SizedBox(height: height);
    }
    var s = mediaSegmentHelper.getMediaSegment();
    if (s == null) {
      return SizedBox(height: height);
    }

    double padding = 16;
    double top = 0;
    double width = MediaQuery.of(Get.context!).size.width;
    if (helper.landscape) {
      padding = MediaQuery.of(Get.context!).padding.left;
      top = helper.topBarHeight;
    }
    width = width - padding * 2;
    double audioBarHeight = 50;
    double videoHeight = width * 9 / 16; // 16:9 视频宽高比

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

    MediaBar? audioBar;
    if (range != null && range.enable) {
      audioBar = MediaBar(
          width: width,
          height: audioBarHeight,
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
          });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      load(path).then((_) {
        mediaKey.currentState?.playFromStart();
      });
    });

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.fromLTRB(padding, top, padding, 0),
        child: ListView(padding: const EdgeInsets.all(0), children: [
          Obx(() {
            return SizedBox(
              width: width,
              height: videoHeight,
              child: initialized.value && _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                      child: VideoPlayer(_videoPlayerController!),
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            );
          }),
          const SizedBox(height: 10),
          if (audioBar != null) audioBar,
          const SizedBox(height: 16),
          if (s.question != null && s.question!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(s.question!, style: const TextStyle(fontSize: 16)),
            ),
          if (helper.step != RepeatStep.recall) Text(s.answer, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Future<void> load(String path) async {
    if (path.isEmpty) return;

    try {
      // 检查是否需要重新初始化播放器
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
      print("Error loading video: $e");
    }
  }

  void onSwitchFullScreen(bool customFullScreen) {
    if (helper != null) {
      helper!.customFullScreen = customFullScreen;
      helper!.update();
    }
  }
}
