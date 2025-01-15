import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/logic/repeat_doc_edit_help.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';
import 'package:repeat_flutter/widget/player_bar/video_mask.dart';

enum RepeatStep { recall, evaluate, finish }

enum ContentType {
  question,
  questionMedia,
  tip,
  answer,
  answerMedia,
}

class ContentArg {
  ContentType contentType;
  bool? tip;

  // The attribute only works for landscape mode.
  bool? left;

  ContentArg(this.contentType, this.tip, this.left);
}

class GsCrRepeatState {
  final GlobalKey<VideoMaskState> videoKey = GlobalKey<VideoMaskState>();

  // for ui
  bool? lastLandscape;
  bool needUpdateSystemUiMode = true;

  static const String mediaId = "m";
  double extendTail = 500.0;
  final GlobalKey<PlayerBarState> mediaKey = GlobalKey<PlayerBarState>();
  var needToPlayMedia = true;
  var ignorePlayingMedia = false;

  var overlayVideoInPortrait = false;
  var concentrationMode = true;

  // for edit
  var edit = false;
  var justViewWithoutRecall = false;

  // for game
  var gamePort = 0;
  var gameMode = false;
  List<String> gameAddress = [];
  RxBool ignoringPunctuation = RxBool(false);

  // for logic
  var nextKey = "";
  var progress = -1;
  var fakeKnow = 0;
  var total = 10;

  SegmentContent segment = SegmentContent(0, 0, 0, 0, 0, 0, "");
  SegmentTodayPrg segmentTodayPrg = SegmentTodayPrg.empty();
  PlayType segmentPlayType = PlayType.none;
  SegmentContent currSegment = SegmentContent(0, 0, 0, 0, 0, 0, "");
  late List<SegmentTodayPrg> c;
  var justView = false;
  var justViewIndex = 0;
  var step = RepeatStep.recall;
  var openTip = false;
  var skipControlMedia = false;
  var pnOffset = 0;

  var showContent = [
    [
      [
        ContentArg(ContentType.question, false, true),
        ContentArg(ContentType.questionMedia, null, null),
        ContentArg(ContentType.tip, true, true),
      ],
      [
        ContentArg(ContentType.question, false, true),
        ContentArg(ContentType.questionMedia, null, null),
        ContentArg(ContentType.answer, false, true),
        ContentArg(ContentType.answerMedia, null, null),
        ContentArg(ContentType.tip, true, true),
      ],
    ],
  ];
}
