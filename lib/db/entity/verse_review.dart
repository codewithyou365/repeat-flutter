// entity/verse_review.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['createDate', 'verseKeyId'],
  indices: [
    Index(value: ['classroomId', 'contentSerial']),
    Index(value: ['classroomId', 'createDate']),
  ],
)
class VerseReview {
  final Date createDate;
  final int verseKeyId;
  final int classroomId;
  final int contentSerial;

  final int count;

  VerseReview(
    this.createDate,
    this.verseKeyId,
    this.classroomId,
    this.contentSerial,
    this.count,
  );
}
