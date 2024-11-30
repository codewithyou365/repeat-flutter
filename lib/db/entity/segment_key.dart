// entity/segment_key.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'materialSerial', 'lessonIndex', 'segmentIndex'], unique: true),
  ],
)
class SegmentKey {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final int classroomId;
  final int materialSerial;
  final int lessonIndex;
  final int segmentIndex;

  SegmentKey(
    this.classroomId,
    this.materialSerial,
    this.lessonIndex,
    this.segmentIndex, {
    this.id,
  });

  String toStringKey() {
    return '$classroomId|$materialSerial|$lessonIndex|$segmentIndex';
  }
}
