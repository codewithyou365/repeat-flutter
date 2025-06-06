// entity/verse_overall_prg.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['verseKeyId'],
  indices: [
    Index(value: ['classroomId', 'next', 'progress']),
    Index(value: ['classroomId', 'contentSerial']),
  ],
)
class VerseOverallPrg {
  int verseKeyId;

  final int classroomId;
  final int contentSerial;
  final Date next;

  final int progress;

  VerseOverallPrg(
    this.verseKeyId,
    this.classroomId,
    this.contentSerial,
    this.next,
    this.progress,
  );
}
