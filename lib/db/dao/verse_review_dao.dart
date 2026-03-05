import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse_review.dart';

@dao
abstract class VerseReviewDao {
  @Query('DELETE FROM VerseReview WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('DELETE FROM VerseReview WHERE bookId=:bookId')
  Future<void> deleteByBookId(int bookId);

  @Query('DELETE FROM VerseReview WHERE chapterId in (:chapterIds)')
  Future<void> deleteByChapterIds(List<int> chapterIds);

  @Query('DELETE FROM VerseReview WHERE chapterId=:chapterId')
  Future<void> deleteByChapterId(int chapterId);

  @Query('DELETE FROM VerseReview WHERE verseId=:verseId')
  Future<void> deleteByVerseId(int verseId);

  @Query('DELETE FROM VerseReview WHERE verseId in (:verseIds)')
  Future<void> deleteByVerseIds(List<int> verseIds);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertOrIgnore(List<VerseReview> review);
}
