import 'package:flutter/widgets.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/logic/segment_edit_help.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';
import 'package:repeat_flutter/widget/player_bar/video_mask.dart';

enum RepeatStep { recall, evaluate, finish }

enum ContentType {
  questionOrPrevAnswerOrTitle,
  questionOrPrevAnswerOrTitleMedia,
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

  // for edit
  var edit = false;
  var justViewWithoutRecall = false;

  // for logic

  var nextKey = "";
  var progress = -1;
  var fakeKnow = 0;
  var total = 10;

  SegmentContent segment = SegmentContent(0, 0, 0, 0, 0, 0, Classroom.curr, "", "", "", "");
  PlayType segmentPlayType = PlayType.none;
  SegmentContent currSegment = SegmentContent(0, 0, 0, 0, 0, 0, Classroom.curr, "", "", "", "");
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
        ContentArg(ContentType.questionOrPrevAnswerOrTitle, false, true),
        ContentArg(ContentType.questionOrPrevAnswerOrTitleMedia, null, null),
        ContentArg(ContentType.tip, true, true),
      ],
      [
        ContentArg(ContentType.questionOrPrevAnswerOrTitle, false, true),
        ContentArg(ContentType.questionOrPrevAnswerOrTitleMedia, null, null),
        ContentArg(ContentType.tip, true, true),
        ContentArg(ContentType.answer, false, true),
        ContentArg(ContentType.answerMedia, null, null),
      ],
    ],
  ];
}
