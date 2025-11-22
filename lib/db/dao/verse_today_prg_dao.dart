import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';

@dao
abstract class VerseTodayPrgDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertsOrFail(List<VerseTodayPrg> entity);

  @Query('SELECT * FROM VerseTodayPrg where type=:type')
  Future<List<VerseTodayPrg>> findByType(int type);

  @Query('DELETE FROM VerseTodayPrg WHERE type=:type')
  Future<void> deleteByType(int type);

  @Query('DELETE FROM VerseTodayPrg WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('DELETE FROM VerseTodayPrg WHERE bookId=:bookId')
  Future<void> deleteByBookId(int bookId);

  @Query('DELETE FROM VerseTodayPrg WHERE chapterId in (:chapterIds)')
  Future<void> deleteByChapterIds(List<int> chapterIds);

  @Query('DELETE FROM VerseTodayPrg WHERE chapterId=:chapterId')
  Future<void> deleteByChapterId(int chapterId);

  @Query('DELETE FROM VerseTodayPrg WHERE verseId=:verseId')
  Future<void> deleteByVerseId(int verseId);

  @Query('DELETE FROM VerseTodayPrg WHERE verseId in (:verseIds)')
  Future<void> deleteByVerseIds(List<int> verseIds);
}
