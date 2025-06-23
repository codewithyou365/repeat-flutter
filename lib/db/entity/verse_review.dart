// entity/verse_review.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['createDate', 'verseKeyId'],
  indices: [
    Index(value: ['bookId']),
    Index(value: ['classroomId', 'createDate']),
  ],
)
class VerseReview {
  final Date createDate;
  final int verseKeyId;
  final int classroomId;
  final int bookId;
  final int chapterKeyId;
  final int count;

  VerseReview({
    required this.createDate,
    required this.verseKeyId,
    required this.classroomId,
    required this.bookId,
    required this.chapterKeyId,
    required this.count,
  });
}
