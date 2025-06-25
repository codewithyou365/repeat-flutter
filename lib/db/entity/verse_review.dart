// entity/verse_review.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['createDate', 'verseId'],
  indices: [
    Index(value: ['bookId']),
    Index(value: ['classroomId', 'createDate']),
  ],
)
class VerseReview {
  final Date createDate;
  final int verseId;
  final int classroomId;
  final int bookId;
  final int chapterId;
  final int count;

  VerseReview({
    required this.createDate,
    required this.verseId,
    required this.classroomId,
    required this.bookId,
    required this.chapterId,
    required this.count,
  });
}
