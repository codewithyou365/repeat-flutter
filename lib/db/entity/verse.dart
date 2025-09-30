// entity/verse.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  indices: [
    Index(value: ['chapterId', 'verseIndex'], unique: true),
    Index(value: ['classroomId', 'sort'], unique: true),
    Index(value: ['classroomId', 'learnDate']),
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
  final String content;
  int contentVersion;

  final Date learnDate;
  final int progress;

  Verse({
    this.id,
    required this.classroomId,
    required this.bookId,
    required this.chapterId,
    required this.chapterIndex,
    required this.verseIndex,
    required this.sort,
    required this.content,
    required this.contentVersion,
    required this.learnDate,
    required this.progress,
  });

  String toStringKey() {
    return '$classroomId|$bookId|$chapterIndex|$verseIndex';
  }
}
