// entity/segment_key.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'contentSerial', 'lessonIndex', 'segmentIndex', 'version'], unique: true),
    Index(value: ['classroomId', 'contentSerial', 'key'], unique: true),
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
  final String key;
  final String segmentContent;

  SegmentKey(
    this.classroomId,
    this.contentSerial,
    this.lessonIndex,
    this.segmentIndex,
    this.version,
    this.key,
    this.segmentContent, {
    this.id,
  });

  String toShortPos() {
    return '$lessonIndex|$segmentIndex';
  }

  SegmentKey clone() {
    SegmentKey ret = SegmentKey(
      classroomId,
      contentSerial,
      lessonIndex,
      segmentIndex,
      version,
      key,
      segmentContent,
      id: id,
    );
    return ret;
  }
}
