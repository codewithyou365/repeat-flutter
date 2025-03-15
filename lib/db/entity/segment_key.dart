// entity/segment_key.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['classroomId', 'segmentHash'],
  indices: [
    Index(value: ['classroomId', 'contentSerial', 'lessonIndex', 'segmentIndex'], unique: true),
  ],
)
class SegmentKey {
  final int classroomId;
  final String segmentHash;

  final int contentSerial;
  final int lessonIndex;
  final int segmentIndex;
  final String segmentContent;

  SegmentKey(
    this.classroomId,
    this.segmentHash,
    this.contentSerial,
    this.lessonIndex,
    this.segmentIndex,
    this.segmentContent,
  );

  String toStringKey() {
    return '$classroomId|$contentSerial|$lessonIndex|$segmentIndex';
  }
}
