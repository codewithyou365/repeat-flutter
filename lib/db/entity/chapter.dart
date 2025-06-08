// entity/chapter.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['chapterKeyId'],
  indices: [
    Index(value: ['classroomId', 'bookSerial', 'chapterIndex'], unique: true),
  ],
)
class Chapter {
  int chapterKeyId;

  final int classroomId;
  final int bookSerial;
  int chapterIndex;

  Chapter({
    this.chapterKeyId = 0,
    required this.classroomId,
    required this.bookSerial,
    required this.chapterIndex,
  });
}
