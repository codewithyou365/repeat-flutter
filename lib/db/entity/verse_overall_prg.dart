// entity/verse_overall_prg.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['verseKeyId'],
  indices: [
    Index(value: ['classroomId', 'next', 'progress']),
    Index(value: ['classroomId']),
    Index(value: ['bookId']),
  ],
)
class VerseOverallPrg {
  int verseKeyId;

  final int classroomId;
  final int bookId;
  int chapterKeyId;
  final Date next;

  final int progress;

  VerseOverallPrg({
    required this.verseKeyId,
    required this.classroomId,
    required this.bookId,
    required this.chapterKeyId,
    required this.next,
    required this.progress,
  });
}
