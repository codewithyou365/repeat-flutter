import 'package:floor/floor.dart';

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
}
