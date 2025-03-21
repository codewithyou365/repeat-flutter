import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/logic/repeat_doc_edit_help.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';
import 'package:repeat_flutter/widget/player_bar/video_mask.dart';

enum RepeatStep { recall, evaluate, finish }

enum TipLevel { none, tip1, tip2 }

enum ContentType {
  question,
  questionMedia,
  tip,
  answer,
  answerMedia,
}

class ContentArg {
  ContentType contentType;
  TipLevel tip;

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
  RxInt matchType = RxInt(MatchType.word.index);
  RxString skipChar = RxString("");
  RxBool editInGame = RxBool(false);

  // for logic
  var nextKey = "";
  var progress = -1;
  var total = 10;

  SegmentContent segment = SegmentContent(0, 0, 0, 0, 0, 0, "");
  SegmentTodayPrg segmentTodayPrg = SegmentTodayPrg.empty();
  PlayType segmentPlayType = PlayType.none;
  SegmentContent currSegment = SegmentContent(0, 0, 0, 0, 0, 0, "");
  late List<SegmentTodayPrg> c;
  var justView = false;
  var justViewIndex = 0;
  var step = RepeatStep.recall;
  var lastRecallTime = 0;
  List<TipLevel> openTip = [];
  var skipControlMedia = false;
  var pnOffset = 0;

  var showContent = [
    [
      [
        ContentArg(ContentType.question, TipLevel.none, true),
        ContentArg(ContentType.questionMedia, TipLevel.none, null),
        ContentArg(ContentType.answer, TipLevel.tip2, true),
        ContentArg(ContentType.tip, TipLevel.tip1, true),
      ],
      [
        ContentArg(ContentType.question, TipLevel.none, true),
        ContentArg(ContentType.questionMedia, TipLevel.none, null),
        ContentArg(ContentType.answer, TipLevel.none, true),
        ContentArg(ContentType.answerMedia, TipLevel.none, null),
        ContentArg(ContentType.tip, TipLevel.tip1, true),
      ],
    ],
  ];
}
