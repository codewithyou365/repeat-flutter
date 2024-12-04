// entity/segment_key.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'contentSerial', 'lessonIndex', 'segmentIndex'], unique: true),
  ],
)
class SegmentKey {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final int classroomId;
  final int contentSerial;
  final int lessonIndex;
  final int segmentIndex;

  SegmentKey(
    this.classroomId,
    this.contentSerial,
    this.lessonIndex,
    this.segmentIndex, {
    this.id,
  });

  String toStringKey() {
    return '$classroomId|$contentSerial|$lessonIndex|$segmentIndex';
  }
}
