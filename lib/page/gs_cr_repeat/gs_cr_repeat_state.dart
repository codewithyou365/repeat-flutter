import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

enum RepeatStep { recall, tip, evaluate, finish }

enum ContentType { questionOrPrevAnswerOrTitleMedia, questionOrPrevAnswerOrTitle, tip, answerMedia, answer }

class GsCrRepeatState {
  // for ui
  final GlobalKey<PlayerBarState> questionMediaKey = GlobalKey<PlayerBarState>();
  final GlobalKey<PlayerBarState> answerMediaKey = GlobalKey<PlayerBarState>();
  var tryNeedPlayQuestion = true;
  var tryNeedPlayAnswer = true;

  // for logic

  var nextKey = "";
  var progress = -1;
  var total = 10;

  SegmentContent segment = SegmentContent(0, 0, 0, 0, 0, 0, Classroom.curr, "", "", "", "");
  late List<SegmentTodayPrg> c;
  var step = RepeatStep.recall;

  var showContent = [
    [
      [
        ContentType.questionOrPrevAnswerOrTitleMedia,
        ContentType.questionOrPrevAnswerOrTitle,
      ],
      [
        ContentType.questionOrPrevAnswerOrTitleMedia,
        ContentType.questionOrPrevAnswerOrTitle,
        ContentType.tip,
      ],
      [
        ContentType.questionOrPrevAnswerOrTitleMedia,
        ContentType.questionOrPrevAnswerOrTitle,
        ContentType.tip,
        ContentType.answerMedia,
        ContentType.answer,
      ],
    ],
  ];
}
