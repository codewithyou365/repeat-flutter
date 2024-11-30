// entity/segment.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['segmentKeyId'],
  indices: [
    Index(value: ['classroomId', 'sort'], unique: true),
    Index(value: ['classroomId', 'materialSerial', 'lessonIndex', 'segmentIndex'], unique: true),
  ],
)
class Segment {
  int segmentKeyId;

  final int classroomId;
  final int materialSerial;
  final int lessonIndex;
  final int segmentIndex;

  final int sort;

  Segment(
    this.segmentKeyId,
    this.classroomId,
    this.materialSerial,
    this.lessonIndex,
    this.segmentIndex,
    this.sort,
  );

  String toStringKey() {
    return '$classroomId|$materialSerial|$lessonIndex|$segmentIndex';
  }
}
