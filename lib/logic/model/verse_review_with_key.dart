import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse_review.dart';

@Entity(tableName: "")
class VerseReviewWithKey extends VerseReview {
  @primaryKey
  String contentName;
  int chapterIndex;
  int verseIndex;

  VerseReviewWithKey(
    super.createDate,
    super.verseKeyId,
    super.classroomId,
    super.bookSerial,
    super.count,
    this.contentName,
    this.chapterIndex,
    this.verseIndex,
  );
}
