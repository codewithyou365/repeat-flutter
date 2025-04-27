// entity/segment.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['segmentKeyId'],
  indices: [
    Index(value: ['classroomId', 'sort'], unique: true),
    Index(value: ['classroomId', 'contentSerial', 'lessonIndex', 'segmentIndex'], unique: true),
  ],
)
class Segment {
  int segmentKeyId;

  final int classroomId;
  final int contentSerial;
  final int lessonIndex;
  int segmentIndex;

  int sort;

  Segment(
    this.segmentKeyId,
    this.classroomId,
    this.contentSerial,
    this.lessonIndex,
    this.segmentIndex,
    this.sort,
  );

  String toStringKey() {
    return '$classroomId|$contentSerial|$lessonIndex|$segmentIndex';
  }
}
