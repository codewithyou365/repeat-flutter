import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:repeat_flutter/widget/audio/media_bar.dart';
import 'constant.dart';
import 'model.dart';
import 'helper.dart';
import 'repeat_view.dart';

class RepeatViewForAudio extends RepeatView {
  static const String playerId = "RepeatViewForAudio";
  final GlobalKey<MediaBarState> mediaKey = GlobalKey<MediaBarState>();
  late AudioPlayer audioPlayer;
  int duration = 0;
  late MediaSegmentHelper mediaSegmentHelper;

  // Ui
  double audioBarHeight = 50;

  RepeatViewForAudio();

  @override
  void init(Helper helper) {
    audioPlayer = AudioPlayer(playerId: playerId);
    this.helper = helper;
    mediaSegmentHelper = MediaSegmentHelper(helper: helper);
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
    var s = mediaSegmentHelper.getMediaSegment();
    if (s == null) {
      return SizedBox(height: height);
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
      return SizedBox(height: height);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      load(path).then((_) {
        mediaKey.currentState?.playFromStart();
      });
    });

    double padding = 16;
    if (helper.landscape) {
      padding = helper.leftPadding;
    }
    height = helper.screenHeight - helper.topPadding - helper.topBarHeight - helper.bottomBarHeight;
    return Column(
      children: [
        SizedBox(height: helper.topPadding),
        helper.topBar(),
        SizedBox(
          height: height,
          child: ListView(padding: const EdgeInsets.all(0), children: [
            Padding(
              padding: EdgeInsets.fromLTRB(padding, 0, padding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mediaBar(helper.screenWidth - padding * 2, audioBarHeight, range),
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

  Future<void> load(String path) async {
    var audioPlayer = this.audioPlayer;
    String prevPath = '';
    Duration? d;
    if (audioPlayer.source != null) {
      final source = audioPlayer.source;
      if (source is DeviceFileSource) {
        prevPath = source.path;
      }
      if (path != prevPath) {
        await audioPlayer.setSource(DeviceFileSource(path));
        d = await audioPlayer.getDuration();
      }
    } else {
      await audioPlayer.setSource(DeviceFileSource(path));
      d = await audioPlayer.getDuration();
      this.audioPlayer = audioPlayer;
    }
    if (d != null) {
      duration = d.inMilliseconds;
    }
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
        await audioPlayer.seek(position);
        await audioPlayer.resume();
      },
      onStop: audioPlayer.stop,
    );
  }
}
