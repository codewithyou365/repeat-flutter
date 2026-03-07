import 'dart:async';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/widgets.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/widget/audio/media_bar.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'constant.dart';
import 'model_media_range.dart';
import 'helper.dart';
import 'repeat_view.dart';

class RepeatViewForAudio extends RepeatView {
  static const String playerId = "RepeatViewForAudio";
  final GlobalKey<MediaBarState> mediaKey = GlobalKey<MediaBarState>();
  late AudioPlayer audioPlayer;
  var lastCurrentPath = "";
  int duration = 0;
  late MediaRangeHelper mediaRangeHelper;
  final SubList<bool> sub = [];

  // Ui
  double mediaBarHeight = 50;
  var currentPath = ''.obs;

  RepeatViewForAudio();

  @override
  void init(Helper helper) {
    audioPlayer = AudioPlayer();
    this.helper = helper;
    mediaRangeHelper = MediaRangeHelper(helper: helper);
    sub.on([EventTopic.stopMedia], (b) {
      mediaKey.currentState?.stop();
    });
    mediaRangeHelper.onInit();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    sub.off();
    mediaRangeHelper.onClose();
  }

  @override
  Widget body() {
    double height = 400;
    Helper? helper = this.helper;
    if (helper == null) {
      return SizedBox(height: height);
    }

    List<String> paths = helper.getPaths();
    if (paths.isNotEmpty) {
      currentPath.value = paths.first;
    }

    final range = mediaRangeHelper.getCurrRange();

    if (helper.enableReloadMedia) {
      helper.enableReloadMedia = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        load(currentPath).then((_) {
          if (helper.doNotPlayMedia) {
            mediaKey.currentState?.drawStart();
          } else if (helper.tryToPlayMedia) {
            helper.tryToPlayMedia = false;
            mediaKey.currentState?.playFromStart();
          }
        });
      });
    }

    double padding = 16;
    if (helper.landscape) {
      padding = helper.leftPadding;
    }
    height = helper.screenHeight - helper.topPadding - helper.topBarHeight - helper.bottomBarHeight - mediaBarHeight;
    var q = helper.text(QaType.question);
    var a = helper.text(QaType.answer);
    var exerciseAreaWidget = helper.exerciseArea.call();
    var tipAreaWidget = helper.tipArea.call();
    return Stack(
      children: [
        Column(
          children: [
            SizedBox(height: helper.topPadding),
            helper.topBar(),
            mediaBar(currentPath, helper.screenWidth - padding * 2, mediaBarHeight, range),
            SizedBox(
              height: height,
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(padding, 0, padding, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (q != null) q,
                        if (q != null) SizedBox(height: RowWidget.dividerHeight),
                        if (a != null) a,
                        if (a != null) SizedBox(height: RowWidget.dividerHeight),
                        if (exerciseAreaWidget != null) exerciseAreaWidget,
                        if (tipAreaWidget != null) tipAreaWidget,
                      ],
                    ),
                  ),
                ],
              ),
            ),
            helper.bottomBar(width: helper.screenWidth),
          ],
        ),
        Obx(() {
          return helper.closeEyesPanel();
        }),
      ],
    );
  }

  bool _isLoading = false;

  Future<void> load(RxString path) async {
    if (_isLoading) return;
    _isLoading = true;
    mediaKey.currentState?.setLoading(_isLoading);

    try {
      var helper = this.helper!;
      final out = DownloadContent(url: '', hash: '');
      var ok = await helper.tryImportMedia(
        localMediaPath: path.value,
        mediaType: MediaType.audio,
        out: out,
      );
      if (!ok) {
        return;
      }
      if (out.hash.isNotEmpty) {
        path.value = helper.getPath(out.path);
      }

      if (path.value == lastCurrentPath && audioPlayer.processingState != ProcessingState.idle) {
        return;
      }

      if (audioPlayer.playing) {
        await audioPlayer.stop();
      }

      await audioPlayer.setFilePath(path.value);

      duration = audioPlayer.duration?.inMilliseconds ?? 0;
      lastCurrentPath = path.value;
    } catch (e) {
      Snackbar.show("Error loading audio: $e");
    } finally {
      _isLoading = false;
      mediaKey.currentState?.setLoading(_isLoading);
    }
  }

  Widget mediaBar(RxString path, double width, double height, MediaRange range) {
    return MediaBar(
      width: width,
      height: height,
      verseStartMs: range.start,
      verseEndMs: range.end,
      key: mediaKey,
      duration: () => duration,
      onPlay: (Duration position) async {
        try {
          helper!.doNotPlayMedia = false;
          await audioPlayer.seek(position);
          audioPlayer.play();
        } catch (e) {
          Snackbar.show("Error playing audio: $e");
        }
      },
      onStop: (bool click) async {
        if (click) {
          helper!.doNotPlayMedia = true;
        }
        await audioPlayer.stop();
      },
      onEdit: mediaRangeHelper.mediaRangeEdit(range),
      onShare: helper!.openMediaShare(),
      onCropAndSave: helper!.cropAndSaveMedia(path: path, range: range),
      onAdjustSpeed: (double speed) async {
        await audioPlayer.setSpeed(speed);
      },
      getSpeed: () => audioPlayer.speed,
      hideTime: helper!.focusMode.value,
    );
  }
}
