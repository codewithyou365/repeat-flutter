// entity/lesson_key.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'contentSerial', 'lessonIndex', 'version'], unique: true),
  ],
)
class LessonKey {
  @PrimaryKey(autoGenerate: true)
  int? id;

  final int classroomId;
  final int contentSerial;
  int lessonIndex;
  int version;
  final String content;
  int contentVersion;

  LessonKey({
    this.id,
    required this.classroomId,
    required this.contentSerial,
    required this.lessonIndex,
    required this.version,
    required this.content,
    required this.contentVersion,
  });

  String get k {
    return "$classroomId-$contentSerial-$lessonIndex";
  }
}
