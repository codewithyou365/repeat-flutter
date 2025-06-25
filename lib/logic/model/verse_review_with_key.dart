import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse_review.dart';

@Entity(tableName: "")
class VerseReviewWithKey extends VerseReview {
  @primaryKey
  String contentName;
  int chapterIndex;
  int verseIndex;

  VerseReviewWithKey({
    required super.createDate,
    required super.verseId,
    required super.classroomId,
    required super.bookId,
    required super.chapterId,
    required super.count,
    required this.contentName,
    required this.chapterIndex,
    required this.verseIndex,
  });
}
