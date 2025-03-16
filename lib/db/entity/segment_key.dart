// entity/segment_key.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'contentSerial', 'lessonIndex', 'segmentIndex', 'version'], unique: true),
  ],
)
class SegmentKey {
  @PrimaryKey(autoGenerate: true)
  int? id;

  final int classroomId;

  final int contentSerial;
  final int lessonIndex;
  final int segmentIndex;
  int version;
  final String segmentContent;

  SegmentKey(
    this.classroomId,
    this.contentSerial,
    this.lessonIndex,
    this.segmentIndex,
    this.version,
    this.segmentContent, {
    this.id,
  });

  String toPos() {
    return '$classroomId|$contentSerial|$lessonIndex|$segmentIndex';
  }

  SegmentKey clone() {
    SegmentKey ret = SegmentKey(
      classroomId,
      contentSerial,
      lessonIndex,
      segmentIndex,
      version,
      segmentContent,
      id: id,
    );
    return ret;
  }
}
