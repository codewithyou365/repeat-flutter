import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:flutter/widgets.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/widget/audio/media_bar.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'constant.dart';
import 'model_media_range.dart';
import 'helper.dart';
import 'repeat_view.dart';

class RepeatViewForAudio extends RepeatView {
  static const String playerId = "RepeatViewForAudio";
  final GlobalKey<MediaBarState> mediaKey = GlobalKey<MediaBarState>();
  late AudioPlayer audioPlayer;
  int duration = 0;
  late MediaRangeHelper mediaRangeHelper;
  final bus = EventBus();
  late StreamSubscription<bool?> sub;

  // Ui
  double mediaBarHeight = 50;

  RepeatViewForAudio();

  @override
  void init(Helper helper) {
    audioPlayer = AudioPlayer();
    this.helper = helper;
    mediaRangeHelper = MediaRangeHelper(helper: helper);
    sub = bus.on<bool>(EventTopic.setInRepeatView).listen((b) {
      mediaKey.currentState?.stop();
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
  }

  @override
  Widget body() {
    double height = 400;
    Helper? helper = this.helper;
    if (helper == null) {
      return SizedBox(height: height);
    }

    var path = '';
    List<String>? paths = helper.getChapterPaths();
    if (paths != null && paths.isNotEmpty) {
      path = paths.first;
    }

    MediaRange? range;
    if (path.isNotEmpty) {
      if (helper.step != RepeatStep.recall) {
        range = mediaRangeHelper.getCurrAnswerRange();
      }
      if (range == null || !range.enable) {
        range = mediaRangeHelper.getCurrQuestionRange();
      }
    }

    if (range == null) {
      return SizedBox(height: height);
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

    double padding = 16;
    if (helper.landscape) {
      padding = helper.leftPadding;
    }
    height = helper.screenHeight - helper.topPadding - helper.topBarHeight - helper.bottomBarHeight - mediaBarHeight;
    var q = helper.text(QaType.question);
    var t = helper.edit || helper.tip == TipLevel.tip ? helper.text(QaType.tip) : null;
    var a = helper.edit || helper.step != RepeatStep.recall ? helper.text(QaType.answer) : null;
    return Column(
      children: [
        SizedBox(height: helper.topPadding),
        helper.topBar(),
        mediaBar(helper.screenWidth - padding * 2, mediaBarHeight, range),
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
                    if (t != null) t,
                    if (a != null) a,
                  ],
                ),
              ),
            ],
          ),
        ),
        helper.bottomBar(width: helper.screenWidth),
      ],
    );
  }

  Future<void> load(String path) async {
    try {
      var helper = this.helper!;
      var ok = await helper.tryImportMedia(
        localMediaPath: path,
        allowedExtensions: ['mp3', 'mp4'],
      );
      if (!ok) {
        return;
      }
      var audioPlayer = this.audioPlayer;
      Duration? d;
      try {
        await audioPlayer.setFilePath(path);
        d = audioPlayer.duration;
      } catch (e) {
        var ok = await helper.tryImportMedia(
          localMediaPath: path,
          allowedExtensions: ['mp3'],
        );
        if (!ok) {
          return;
        }
        await audioPlayer.setFilePath(path);
        d = audioPlayer.duration;
      }
      if (d != null) {
        duration = d.inMilliseconds;
      }
    } catch (e) {
      Snackbar.show("Error loading audio: $e");
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
        await audioPlayer.seek(position);
        try {
          await audioPlayer.play().timeout(const Duration(milliseconds: 50));
        } catch (e) {
          if (e is! TimeoutException) rethrow;
          await audioPlayer.play();
        }
      },
      onStop: audioPlayer.stop,
      onEdit: mediaRangeHelper.mediaRangeEdit(range),
    );
  }
}
