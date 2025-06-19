// entity/chapter.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['chapterKeyId'],
  indices: [
    Index(value: ['classroomId']),
    Index(value: ['bookId', 'chapterIndex'], unique: true),
  ],
)
class Chapter {
  int chapterKeyId;

  final int classroomId;
  final int bookId;
  int chapterIndex;

  Chapter({
    this.chapterKeyId = 0,
    required this.classroomId,
    required this.bookId,
    required this.chapterIndex,
  });
}
