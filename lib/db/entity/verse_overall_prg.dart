// entity/verse_overall_prg.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['verseId'],
  indices: [
    Index(value: ['classroomId', 'next', 'progress']),
    Index(value: ['classroomId']),
    Index(value: ['bookId']),
  ],
)
class VerseOverallPrg {
  int verseId;

  final int classroomId;
  final int bookId;
  int chapterId;
  final Date next;

  final int progress;

  VerseOverallPrg({
    required this.verseId,
    required this.classroomId,
    required this.bookId,
    required this.chapterId,
    required this.next,
    required this.progress,
  });
}
