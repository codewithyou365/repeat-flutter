// entity/chapter.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['chapterKeyId'],
  indices: [
    Index(value: ['classroomId', 'contentSerial', 'chapterIndex'], unique: true),
  ],
)
class Chapter {
  int chapterKeyId;

  final int classroomId;
  final int contentSerial;
  int chapterIndex;

  Chapter({
    this.chapterKeyId = 0,
    required this.classroomId,
    required this.contentSerial,
    required this.chapterIndex,
  });
}
