import 'package:repeat_flutter/db/entity/segment_today_prg.dart';

class SegmentTodayPrgInView {
  int index;
  int uniqIndex;
  String name;
  TodayPrgType type;
  String groupDesc;
  String desc;

  List<SegmentTodayPrg> segments;

  SegmentTodayPrgInView(
    this.segments, {
    this.index = 0,
    this.uniqIndex = 0,
    this.name = "",
    this.type = TodayPrgType.none,
    this.groupDesc = "",
    this.desc = "",
  });
}

class GsCrState {
  List<SegmentTodayPrgInView> segments = [];
  List<SegmentTodayPrg> all = [];
  List<SegmentTodayPrg> learn = [];
  List<SegmentTodayPrg> review = [];

  var learnedTotalCount = 0;
  var learnTotalCount = 0;
  var learnDeadlineTips = "";
  int learnDeadline = 0;
}
