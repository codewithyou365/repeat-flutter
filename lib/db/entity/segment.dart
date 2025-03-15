// entity/segment.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['classroomId', 'segmentHash'],
  indices: [
    Index(value: ['classroomId', 'sort'], unique: true),
    Index(value: ['classroomId', 'contentSerial', 'lessonIndex', 'segmentIndex'], unique: true),
  ],
)
class Segment {
  final int classroomId;
  String segmentHash;

  final int contentSerial;
  final int lessonIndex;
  final int segmentIndex;

  final int sort;

  Segment(
    this.classroomId,
    this.segmentHash,
    this.contentSerial,
    this.lessonIndex,
    this.segmentIndex,
    this.sort,
  );

  String toStringKey() {
    return '$classroomId|$contentSerial|$lessonIndex|$segmentIndex';
  }
}
