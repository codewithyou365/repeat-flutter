import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse_key.dart';

@dao
abstract class VerseKeyDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(VerseKey entity);

  @Query('SELECT * FROM VerseKey where id=:id')
  Future<VerseKey?> oneById(int id);

  @Query('SELECT count(id) FROM VerseKey where classroomId=:classroomId and contentSerial=:contentSerial chapterIndex=:chapterIndex')
  Future<int?> count(int classroomId, int contentSerial, int chapterIndex);

  @Query('SELECT * FROM VerseKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND chapterIndex=:chapterIndex AND verseIndex>=:minVerseIndex')
  Future<List<VerseKey>> findByMinVerseIndex(int classroomId, int contentSerial, int chapterIndex, int minVerseIndex);

  @Query('DELETE FROM VerseKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND chapterIndex=:chapterIndex AND verseIndex>=:minVerseIndex')
  Future<void> deleteByMinVerseIndex(int classroomId, int contentSerial, int chapterIndex, int minVerseIndex);

  @Query('SELECT * FROM VerseKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND chapterIndex>=:minChapterIndex')
  Future<List<VerseKey>> findByMinChapterIndex(int classroomId, int contentSerial, int minChapterIndex);

  @Query('DELETE FROM VerseKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND chapterIndex>=:minChapterIndex')
  Future<void> deleteByMinChapterIndex(int classroomId, int contentSerial, int minChapterIndex);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertListOrFail(List<VerseKey> entities);
}
