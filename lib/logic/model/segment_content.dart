import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

@Entity(tableName: "")
class SegmentContentInDb extends Segment {
  @primaryKey
  final String materialName;

  SegmentContentInDb(
    super.segmentKeyId,
    super.classroomId,
    super.materialSerial,
    super.lessonIndex,
    super.segmentIndex,
    super.sort,
    this.materialName,
  );
}

class SegmentContent extends SegmentContentInDb {
  List<MediaSegment> qMediaSegments = [];
  List<MediaSegment> aMediaSegments = [];
  MediaSegment? titleMediaSegment;
  var mediaDocPath = "";
  var mediaExtension = "";
  var title = "";
  var prevAnswer = "";
  var question = "";
  var tip = "";
  var answer = "";
  var k = "";
  var miss = false;

  SegmentContent(
    super.segmentKeyId,
    super.classroomId,
    super.materialSerial,
    super.lessonIndex,
    super.segmentIndex,
    super.sort,
    super.materialName,
  );

  static SegmentContent from(SegmentContentInDb d) {
    return SegmentContent(
      d.segmentKeyId,
      d.classroomId,
      d.materialSerial,
      d.lessonIndex,
      d.segmentIndex,
      d.sort,
      d.materialName,
    );
  }
}
