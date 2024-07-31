import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/logic/model/segment_today_prg_with_key.dart';

class SegmentTodayPrgWithKeyInView {
  int index;
  int uniqIndex;
  String name;
  TodayPrgType type;
  String groupDesc;
  String desc;

  List<SegmentTodayPrgWithKey> segments;

  SegmentTodayPrgWithKeyInView(
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
  List<SegmentTodayPrgWithKeyInView> segments = [];
  List<SegmentTodayPrgWithKey> all = [];
  List<SegmentTodayPrgWithKey> learn = [];
  List<SegmentTodayPrgWithKey> review = [];

  var learnedTotalCount = 0;
  var learnTotalCount = 0;
  var learnDeadlineTips = "";
  int learnDeadline = 0;
}
