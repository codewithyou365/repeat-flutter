// entity/chapter.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['classroomId']),
    Index(value: ['bookId', 'chapterIndex'], unique: true),
  ],
)
class Chapter {
  @PrimaryKey(autoGenerate: true)
  int? id;

  final int classroomId;
  final int bookId;
  int chapterIndex;
  String content;
  int contentVersion;

  Chapter({
    this.id,
    required this.classroomId,
    required this.bookId,
    required this.chapterIndex,
    required this.content,
    required this.contentVersion,
  });

  static Chapter empty() {
    return Chapter(
      id: null,
      classroomId: 0,
      bookId: 0,
      chapterIndex: 0,
      content: '',
      contentVersion: 0,
    );
  }
}
