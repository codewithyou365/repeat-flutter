import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/logic/model/qa_repeat_file.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';

enum MainRepeatStep { recall, evaluate, finish }

// recall by value
// recall by media (audio, video or image)
// recall by key

enum MainRepeatMode { byQuestion, byMedia, byKey }

class MainRepeatState {
  var progress = -1;
  var total = 10;

  SegmentContent segment = SegmentContent("", 0, 0, 0, 0, "", "", "");
  late List<SegmentTodayPrg> c;



  var step = MainRepeatStep.recall;
  var mode = MainRepeatMode.byQuestion;
}
