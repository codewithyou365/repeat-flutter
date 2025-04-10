// entity/lesson_key.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['lessonKeyId'],
  indices: [
    Index(value: ['classroomId', 'contentSerial', 'lessonIndex'], unique: true),
  ],
)
class Lesson {
  int lessonKeyId;

  late final int classroomId;
  late final int contentSerial;
  late final int lessonIndex;

  Lesson({
    this.lessonKeyId = 0,
    required this.classroomId,
    required this.contentSerial,
    required this.lessonIndex,
  });
}
