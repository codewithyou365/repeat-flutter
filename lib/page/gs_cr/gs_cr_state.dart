import 'package:repeat_flutter/db/entity/content.dart';
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

class ForAdd {
  List<Content> contents = [];
  List<String> contentNames = [];
  int maxLesson = 1;
  int maxSegment = 1;

  Content? fromContent;
  int fromContentIndex = 0;
  int fromLessonIndex = 0;
  int fromSegmentIndex = 0;
  int count = 1;
}

class GsCrState {
  List<SegmentTodayPrgInView> segments = [];
  List<SegmentTodayPrg> all = [];
  List<SegmentTodayPrg> learn = [];
  List<SegmentTodayPrg> review = [];
  List<SegmentTodayPrg> fullCustom = [];

  ForAdd forAdd = ForAdd();

  var learnedTotalCount = 0;
  var learnTotalCount = 0;
  var learnDeadlineTips = "";
  int learnDeadline = 0;
}
