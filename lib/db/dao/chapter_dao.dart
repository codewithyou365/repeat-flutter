// dao/chapter_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/chapter.dart';

@dao
abstract class ChapterDao {
  @Query('SELECT * FROM Chapter WHERE classroomId=:classroomId and bookSerial=:bookSerial')
  Future<List<Chapter>> find(int classroomId, int bookSerial);

  @Query('SELECT * FROM Chapter WHERE classroomId=:classroomId and bookSerial=:bookSerial and chapterIndex=:chapterIndex')
  Future<Chapter?> one(int classroomId, int bookSerial, int chapterIndex);

  @Query('SELECT count(1) FROM Chapter'
      ' WHERE classroomId=:classroomId AND bookSerial=:bookSerial')
  Future<int?> count(int classroomId, int bookSerial);

  @Query('SELECT * FROM Chapter'
      ' WHERE classroomId=:classroomId AND bookSerial=:bookSerial AND chapterIndex>=:minChapterIndex')
  Future<List<Chapter>> findByMinChapterIndex(int classroomId, int bookSerial, int minChapterIndex);

  @Query('DELETE FROM Chapter'
      ' WHERE classroomId=:classroomId AND bookSerial=:bookSerial AND chapterIndex>=:minChapterIndex')
  Future<void> deleteByMinChapterIndex(int classroomId, int bookSerial, int minChapterIndex);

  @Query('DELETE FROM Chapter'
      ' WHERE Chapter.classroomId=:classroomId'
      ' and Chapter.bookSerial=:bookSerial')
  Future<void> delete(int classroomId, int bookSerial);

  @Query('DELETE FROM Chapter'
      ' WHERE Chapter.classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('DELETE FROM ChapterKey WHERE id=:id')
  Future<void> deleteById(int id);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(List<Chapter> entities);
}
