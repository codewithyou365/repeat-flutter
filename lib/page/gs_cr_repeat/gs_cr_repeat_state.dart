import 'package:repeat_flutter/db/entity/segment_current_prg.dart';
import 'package:repeat_flutter/db/entity/segment_today_review.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';

enum RepeatStep { recall, evaluate, finish }

// recall by value
// recall by media (audio, video or image)
// recall by key

enum RepeatMode { byQuestion, byMedia, byKey }

class GsCrRepeatState {
  var progress = -1;
  var total = 10;

  SegmentContent segment = SegmentContent("", 0, 0, 0, 0, 0, "", "", "");
  late List<SegmentCurrentPrg> c;
  Map<String, List<SegmentTodayReview>>? forReview;
  var step = RepeatStep.recall;
  var mode = RepeatMode.byQuestion;
}
