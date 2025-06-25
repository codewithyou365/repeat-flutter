import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse_overall_prg.dart';

@dao
abstract class VerseOverallPrgDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(VerseOverallPrg entity);

  @Query('DELETE FROM VerseOverallPrg WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('DELETE FROM VerseOverallPrg WHERE chapterId=:chapterId')
  Future<void> deleteByChapterId(int chapterId);

  @Query('DELETE FROM VerseOverallPrg WHERE verseId=:verseId')
  Future<void> deleteByVerseId(int verseId);
}
