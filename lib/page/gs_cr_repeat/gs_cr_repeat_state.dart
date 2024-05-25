import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';

enum RepeatStep { recall, tip, evaluate, finish }

// recall by value
// recall by media (audio, video or image)
// recall by key

enum ContentType { questionOrPrevAnswerOrTitle, tip, answer, media, padding }

class GsCrRepeatState {

  // for ui
  final GlobalKey questionKey = GlobalKey();
  RxDouble questionHeight = (-1.0).obs;

  // for logic
  var progress = -1;
  var total = 10;

  SegmentContent segment = SegmentContent(0, 0, 0, 0, 0, 0, Classroom.curr, "", "", "", "");
  late List<SegmentTodayPrg> c;
  var step = RepeatStep.recall;
  var showContent = [
    [
      [ContentType.questionOrPrevAnswerOrTitle],
      [ContentType.questionOrPrevAnswerOrTitle, ContentType.tip],
      [ContentType.questionOrPrevAnswerOrTitle, ContentType.media, ContentType.tip, ContentType.padding, ContentType.answer]
    ],
  ];
}
