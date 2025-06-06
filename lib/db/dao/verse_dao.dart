import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse.dart';

@dao
abstract class VerseDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(Verse entity);

  @Query('SELECT * FROM Verse'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex=:lessonIndex AND verseIndex=:verseIndex')
  Future<Verse?> one(int classroomId, int contentSerial, int lessonIndex, int verseIndex);

  @Query('SELECT * FROM Verse'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex>=:minLessonIndex order by lessonIndex,verseIndex limit 1')
  Future<Verse?> last(int classroomId, int contentSerial, int minLessonIndex);

  @Query('SELECT * FROM Verse'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex=:lessonIndex AND verseIndex>=:minVerseIndex')
  Future<List<Verse>> findByMinVerseIndex(int classroomId, int contentSerial, int lessonIndex, int minVerseIndex);

  @Query('DELETE FROM Verse'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex=:lessonIndex AND verseIndex>=:minVerseIndex')
  Future<void> deleteByMinVerseIndex(int classroomId, int contentSerial, int lessonIndex, int minVerseIndex);

  @Query('SELECT * FROM Verse'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex>=:minLessonIndex')
  Future<List<Verse>> findByMinLessonIndex(int classroomId, int contentSerial, int minLessonIndex);

  @Query('DELETE FROM Verse'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex>=:minLessonIndex')
  Future<void> deleteByMinLessonIndex(int classroomId, int contentSerial, int minLessonIndex);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertListOrFail(List<Verse> entities);
}
