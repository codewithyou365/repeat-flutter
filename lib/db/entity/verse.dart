// entity/verse.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['verseKeyId'],
  indices: [
    Index(value: ['chapterKeyId']),
    Index(value: ['classroomId', 'sort'], unique: true),
    Index(value: ['bookId', 'chapterIndex', 'verseIndex'], unique: true),
  ],
)
class Verse {
  int verseKeyId;

  final int classroomId;
  final int bookId;
  int chapterKeyId;
  int chapterIndex;
  int verseIndex;

  int sort;

  Verse({
    required this.verseKeyId,
    required this.classroomId,
    required this.bookId,
    required this.chapterKeyId,
    required this.chapterIndex,
    required this.verseIndex,
    required this.sort,
  });

  String toStringKey() {
    return '$classroomId|$bookId|$chapterIndex|$verseIndex';
  }
}
