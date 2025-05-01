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
  int lessonIndex;
  int segmentIndex;

  int sort;

  Segment({
    required this.segmentKeyId,
    required this.classroomId,
    required this.contentSerial,
    required this.lessonIndex,
    required this.segmentIndex,
    required this.sort,
  });

  String toStringKey() {
    return '$classroomId|$contentSerial|$lessonIndex|$segmentIndex';
  }
}
