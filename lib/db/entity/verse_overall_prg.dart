// entity/verse_overall_prg.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['verseKeyId'],
  indices: [
    Index(value: ['classroomId', 'next', 'progress']),
    Index(value: ['classroomId', 'bookSerial']),
  ],
)
class VerseOverallPrg {
  int verseKeyId;

  final int classroomId;
  final int bookSerial;
  final Date next;

  final int progress;

  VerseOverallPrg(
    this.verseKeyId,
    this.classroomId,
    this.bookSerial,
    this.next,
    this.progress,
  );
}
