import 'package:flutter/widgets.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

enum RepeatStep { recall, evaluate, finish }

enum ContentType { questionOrPrevAnswerOrTitleMedia, questionOrPrevAnswerOrTitle, tip, answerMedia, answerMediaWithPnController, answerPnController, answer }

class ContentTypeWithTip {
  ContentType contentType;
  bool tip;

  ContentTypeWithTip(this.contentType, this.tip);
}

class GsCrRepeatState {
  // for ui
  final String questionMediaId = "qm";
  final String answerMediaId = "am";
  final GlobalKey<PlayerBarState> questionMediaKey = GlobalKey<PlayerBarState>();
  final GlobalKey<PlayerBarState> answerMediaKey = GlobalKey<PlayerBarState>();
  var tryNeedPlayQuestion = true;
  var tryNeedPlayAnswer = true;

  // for logic

  var nextKey = "";
  var progress = -1;
  var fakeKnow = 0;
  var total = 10;

  SegmentContent segment = SegmentContent(0, 0, 0, 0, 0, 0, Classroom.curr, "", "", "", "");
  late List<SegmentTodayPrg> c;
  var justView = false;
  var justViewIndex = 0;
  var step = RepeatStep.recall;
  var openTip = false;
  var pnOffset = 0;

  var showContent = [
    [
      [
        ContentTypeWithTip(ContentType.questionOrPrevAnswerOrTitleMedia, false),
        ContentTypeWithTip(ContentType.questionOrPrevAnswerOrTitle, false),
        ContentTypeWithTip(ContentType.tip, true),
      ],
      [
        ContentTypeWithTip(ContentType.questionOrPrevAnswerOrTitleMedia, false),
        ContentTypeWithTip(ContentType.questionOrPrevAnswerOrTitle, false),
        ContentTypeWithTip(ContentType.answerMediaWithPnController, false),
        ContentTypeWithTip(ContentType.answer, false),
        ContentTypeWithTip(ContentType.tip, true),
      ],
    ],
  ];
}
