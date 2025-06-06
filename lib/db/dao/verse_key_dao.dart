import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse_key.dart';

@dao
abstract class VerseKeyDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(VerseKey entity);

  @Query('SELECT * FROM VerseKey where id=:id')
  Future<VerseKey?> oneById(int id);

  @Query('SELECT count(id) FROM VerseKey where classroomId=:classroomId and contentSerial=:contentSerial lessonIndex=:lessonIndex')
  Future<int?> count(int classroomId, int contentSerial, int lessonIndex);

  @Query('SELECT * FROM VerseKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex=:lessonIndex AND verseIndex>=:minVerseIndex')
  Future<List<VerseKey>> findByMinVerseIndex(int classroomId, int contentSerial, int lessonIndex, int minVerseIndex);

  @Query('DELETE FROM VerseKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex=:lessonIndex AND verseIndex>=:minVerseIndex')
  Future<void> deleteByMinVerseIndex(int classroomId, int contentSerial, int lessonIndex, int minVerseIndex);

  @Query('SELECT * FROM VerseKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex>=:minLessonIndex')
  Future<List<VerseKey>> findByMinLessonIndex(int classroomId, int contentSerial, int minLessonIndex);

  @Query('DELETE FROM VerseKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex>=:minLessonIndex')
  Future<void> deleteByMinLessonIndex(int classroomId, int contentSerial, int minLessonIndex);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertListOrFail(List<VerseKey> entities);
}
