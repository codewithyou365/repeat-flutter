import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
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
          await audioPlayer.seek(position);
          await audioPlayer.resume();
        },
        onStop: audioPlayer.stop,
      );
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
          if (audioBar != null) audioBar,
          if (s.question != null && s.question!.isNotEmpty) Text(s.question!),
          if (helper.step != RepeatStep.recall) Text(s.answer),
        ]),
      ),
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
}
