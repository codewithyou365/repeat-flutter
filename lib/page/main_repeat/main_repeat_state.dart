import 'package:repeat_flutter/db/entity/segment_current_prg.dart';
import 'package:repeat_flutter/db/entity/segment_today_review.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';

enum MainRepeatStep { recall, evaluate, finish }

// recall by value
// recall by media (audio, video or image)
// recall by key

enum MainRepeatMode { byQuestion, byMedia, byKey }

class MainRepeatState {
  var progress = -1;
  var total = 10;

  SegmentContent segment = SegmentContent("", 0, 0, 0, 0, 0, "", "", "");
  late List<SegmentCurrentPrg> c;
  Map<String, List<SegmentTodayReview>>? forReview;
  var step = MainRepeatStep.recall;
  var mode = MainRepeatMode.byQuestion;
}
