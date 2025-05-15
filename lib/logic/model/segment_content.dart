import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment.dart';

@Entity(tableName: "")
class SegmentContentInDb extends Segment {
  @primaryKey
  final String contentName;

  SegmentContentInDb({
    required super.segmentKeyId,
    required super.classroomId,
    required super.contentSerial,
    required super.lessonIndex,
    required super.segmentIndex,
    required super.sort,
    required this.contentName,
  });
}

class SegmentContent extends SegmentContentInDb {
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

  SegmentContent({
    required super.segmentKeyId,
    required super.classroomId,
    required super.contentSerial,
    required super.lessonIndex,
    required super.segmentIndex,
    required super.sort,
    required super.contentName,
  });

  static SegmentContent empty() {
    return SegmentContent(
      segmentKeyId: 0,
      classroomId: 0,
      contentSerial: 0,
      lessonIndex: 0,
      segmentIndex: 0,
      sort: 0,
      contentName: "",
    );
  }

  static SegmentContent from(SegmentContentInDb d) {
    return SegmentContent(
      segmentKeyId: d.segmentKeyId,
      classroomId: d.classroomId,
      contentSerial: d.contentSerial,
      lessonIndex: d.lessonIndex,
      segmentIndex: d.segmentIndex,
      sort: d.sort,
      contentName: d.contentName,
    );
  }
}
