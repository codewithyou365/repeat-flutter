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

  late final int classroomId;
  late final int contentSerial;
  late final int lessonIndex;
  late int version;
  late final String content;
  late int contentVersion;

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
