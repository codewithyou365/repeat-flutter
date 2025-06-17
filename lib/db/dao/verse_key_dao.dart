import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse_key.dart';

@dao
abstract class VerseKeyDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(VerseKey entity);

  @Query('SELECT * FROM VerseKey where id=:id')
  Future<VerseKey?> oneById(int id);

  @Query('SELECT count(id) FROM VerseKey where classroomId=:classroomId and bookSerial=:bookSerial chapterIndex=:chapterIndex')
  Future<int?> count(int classroomId, int bookSerial, int chapterIndex);

  @Query('SELECT * FROM VerseKey'
      ' WHERE classroomId=:classroomId AND bookSerial=:bookSerial AND chapterIndex=:chapterIndex AND verseIndex>=:minVerseIndex')
  Future<List<VerseKey>> findByMinVerseIndex(int classroomId, int bookSerial, int chapterIndex, int minVerseIndex);

  @Query('DELETE FROM VerseKey'
      ' WHERE classroomId=:classroomId AND bookSerial=:bookSerial AND chapterIndex=:chapterIndex AND verseIndex>=:minVerseIndex')
  Future<void> deleteByMinVerseIndex(int classroomId, int bookSerial, int chapterIndex, int minVerseIndex);

  @Query('SELECT * FROM VerseKey'
      ' WHERE classroomId=:classroomId AND bookSerial=:bookSerial AND chapterIndex>=:minChapterIndex')
  Future<List<VerseKey>> findByMinChapterIndex(int classroomId, int bookSerial, int minChapterIndex);

  @Query('DELETE FROM VerseKey'
      ' WHERE classroomId=:classroomId AND bookSerial=:bookSerial AND chapterIndex>=:minChapterIndex')
  Future<void> deleteByMinChapterIndex(int classroomId, int bookSerial, int minChapterIndex);

  @Query('DELETE FROM VerseKey WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertListOrFail(List<VerseKey> entities);
}
