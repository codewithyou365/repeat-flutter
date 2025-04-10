// entity/segment_key.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'contentSerial', 'lessonIndex', 'segmentIndex', 'version'], unique: true),
    Index(value: ['classroomId', 'contentSerial', 'k'], unique: true),
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
  final String k;
  final String content;
  int contentVersion;
  final String note;
  int noteVersion;

  SegmentKey({
    required this.classroomId,
    required this.contentSerial,
    required this.lessonIndex,
    required this.segmentIndex,
    required this.version,
    required this.k,
    required this.content,
    required this.contentVersion,
    required this.note,
    required this.noteVersion,
    this.id,
  });
}
