import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';

enum RepeatStep { recall, tip, evaluate, finish }

// recall by value
// recall by media (audio, video or image)
// recall by key

enum ContentType { prevAnswerOrTitle, question, answer, media, padding }

class GsCrRepeatState {
  var progress = -1;
  var total = 10;

  SegmentContent segment = SegmentContent(Classroom.curr, "", 0, 0, 0, 0, 0, "", "", "");
  late List<SegmentTodayPrg> c;
  var step = RepeatStep.recall;
  var showContent = [
    [
      [ContentType.prevAnswerOrTitle],
      [ContentType.prevAnswerOrTitle, ContentType.question],
      [ContentType.prevAnswerOrTitle, ContentType.question, ContentType.padding, ContentType.answer, ContentType.media]
    ],
  ];
}
