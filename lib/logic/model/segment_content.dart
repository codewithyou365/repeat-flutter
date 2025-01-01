import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

@Entity(tableName: "")
class SegmentContentInDb extends Segment {
  @primaryKey
  final String contentName;

  SegmentContentInDb(
    super.segmentKeyId,
    super.classroomId,
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
  MediaSegment? titleMediaSegment;
  var mediaDocPath = "";
  var mediaHash = "";
  var mediaExtension = "";
  var title = "";
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
    super.segmentKeyId,
    super.classroomId,
    super.contentSerial,
    super.lessonIndex,
    super.segmentIndex,
    super.sort,
    super.contentName,
  );

  static SegmentContent from(SegmentContentInDb d) {
    return SegmentContent(
      d.segmentKeyId,
      d.classroomId,
      d.contentSerial,
      d.lessonIndex,
      d.segmentIndex,
      d.sort,
      d.contentName,
    );
  }
}
