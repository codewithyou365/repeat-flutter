// entity/verse.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['chapterId']),
    Index(value: ['classroomId', 'sort'], unique: true),
    Index(value: ['bookId', 'chapterIndex', 'verseIndex'], unique: true),
  ],
)
class Verse {
  @PrimaryKey(autoGenerate: true)
  int? id;

  final int classroomId;
  final int bookId;
  int chapterId;
  int chapterIndex;
  int verseIndex;
  int sort;
  final String k;
  final String content;
  int contentVersion;
  final String note;
  int noteVersion;

  Verse({
    this.id,
    required this.classroomId,
    required this.bookId,
    required this.chapterId,
    required this.chapterIndex,
    required this.verseIndex,
    required this.sort,
    required this.k,
    required this.content,
    required this.contentVersion,
    required this.note,
    required this.noteVersion,
  });

  String toStringKey() {
    return '$classroomId|$bookId|$chapterIndex|$verseIndex';
  }
}
