import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

@Entity(tableName: "")
class SegmentContentInDb extends Segment {
  @primaryKey
  final String contentName;

  SegmentContentInDb(
    super.classroomId,
    super.segmentHash,
    super.contentSerial,
    super.lessonIndex,
    super.segmentIndex,
    super.sort,
    this.contentName,
  );
}

class SegmentContent extends SegmentContentInDb {
  List<MediaSegment> qMediaSegments = [];
  List<MediaSegment> aMediaSegments = [];
  var mediaDocPath = "";
  var mediaHash = "";
  var mediaExtension = "";
  var prevAnswer = "";
  var question = "";
  var tip = "";
  var answer = "";
  var aStart = "";
  var aEnd = "";
  var word = "";
  var k = "";
  var miss = false;

  SegmentContent(
    super.classroomId,
    super.segmentHash,
    super.contentSerial,
    super.lessonIndex,
    super.segmentIndex,
    super.sort,
    super.contentName,
  );

  static SegmentContent from(SegmentContentInDb d) {
    return SegmentContent(
      d.classroomId,
      d.segmentHash,
      d.contentSerial,
      d.lessonIndex,
      d.segmentIndex,
      d.sort,
      d.contentName,
    );
  }
}
