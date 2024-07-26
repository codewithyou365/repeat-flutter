import 'package:get/get.dart';
import 'package:repeat_flutter/logic/model/segment_today_prg_with_key.dart';

class SegmentTodayPrgWithKeyInView {
  int index;
  int uniqIndex;
  String group;
  String name;
  String desc;

  List<SegmentTodayPrgWithKey> segments;

  SegmentTodayPrgWithKeyInView(
    this.index,
    this.uniqIndex,
    this.name,
    this.group,
    this.desc,
    this.segments,
  );
}

class GsCrState {
  List<SegmentTodayPrgWithKeyInView> segments = [];

  var learnTotalCount = 0.obs;
  var reviewTotalCount = 0.obs;
  var learnDeadlineTips = "".obs;
  int learnDeadline = 0;
}
