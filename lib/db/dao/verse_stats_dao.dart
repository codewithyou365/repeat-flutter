import 'package:floor/floor.dart';

@dao
abstract class VerseStatsDao {
  @Query('DELETE FROM VerseStats WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('DELETE FROM VerseStats WHERE bookId=:bookId')
  Future<void> deleteByBookId(int bookId);

  @Query('DELETE FROM VerseStats WHERE chapterId in (:chapterIds)')
  Future<void> deleteByChapterIds(List<int> chapterIds);

  @Query('DELETE FROM VerseStats WHERE chapterId=:chapterId')
  Future<void> deleteByChapterId(int chapterId);

  @Query('DELETE FROM VerseStats WHERE verseId=:verseId')
  Future<void> deleteByVerseId(int verseId);

  @Query('DELETE FROM VerseStats WHERE verseId in (:verseIds)')
  Future<void> deleteByVerseIds(List<int> verseIds);
}
