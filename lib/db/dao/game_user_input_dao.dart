import 'package:floor/floor.dart';

@dao
abstract class GameUserInputDao {
  @Query('DELETE FROM GameUserInput WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('DELETE FROM GameUserInput WHERE bookId=:bookId')
  Future<void> deleteByBookId(int bookId);

  @Query('DELETE FROM GameUserInput WHERE chapterId=:chapterId')
  Future<void> deleteByChapterId(int chapterId);

  @Query('DELETE FROM GameUserInput WHERE chapterId in (:chapterIds)')
  Future<void> deleteByChapterIds(List<int> chapterIds);

  @Query('DELETE FROM GameUserInput WHERE verseId=:verseId')
  Future<void> deleteByVerseId(int verseId);

  @Query('DELETE FROM GameUserInput WHERE verseId in (:verseIds)')
  Future<void> deleteByVerseIds(List<int> verseIds);
}
