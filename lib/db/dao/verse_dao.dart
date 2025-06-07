import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse.dart';

@dao
abstract class VerseDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(Verse entity);

  @Query('SELECT * FROM Verse'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND chapterIndex=:chapterIndex AND verseIndex=:verseIndex')
  Future<Verse?> one(int classroomId, int contentSerial, int chapterIndex, int verseIndex);

  @Query('SELECT * FROM Verse'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND chapterIndex>=:minChapterIndex order by chapterIndex,verseIndex limit 1')
  Future<Verse?> last(int classroomId, int contentSerial, int minChapterIndex);

  @Query('SELECT * FROM Verse'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND chapterIndex=:chapterIndex AND verseIndex>=:minVerseIndex')
  Future<List<Verse>> findByMinVerseIndex(int classroomId, int contentSerial, int chapterIndex, int minVerseIndex);

  @Query('DELETE FROM Verse'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND chapterIndex=:chapterIndex AND verseIndex>=:minVerseIndex')
  Future<void> deleteByMinVerseIndex(int classroomId, int contentSerial, int chapterIndex, int minVerseIndex);

  @Query('SELECT * FROM Verse'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND chapterIndex>=:minChapterIndex')
  Future<List<Verse>> findByMinChapterIndex(int classroomId, int contentSerial, int minChapterIndex);

  @Query('DELETE FROM Verse'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND chapterIndex>=:minChapterIndex')
  Future<void> deleteByMinChapterIndex(int classroomId, int contentSerial, int minChapterIndex);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertListOrFail(List<Verse> entities);
}
