// dao/chapter_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/chapter.dart';

@dao
abstract class ChapterDao {
  @Query('SELECT * FROM Chapter WHERE classroomId=:classroomId and contentSerial=:contentSerial')
  Future<List<Chapter>> find(int classroomId, int contentSerial);

  @Query('SELECT * FROM Chapter WHERE classroomId=:classroomId and contentSerial=:contentSerial and chapterIndex=:chapterIndex')
  Future<Chapter?> one(int classroomId, int contentSerial, int chapterIndex);

  @Query('SELECT count(1) FROM Chapter'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial')
  Future<int?> count(int classroomId, int contentSerial);

  @Query('SELECT * FROM Chapter'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND chapterIndex>=:minChapterIndex')
  Future<List<Chapter>> findByMinChapterIndex(int classroomId, int contentSerial, int minChapterIndex);

  @Query('DELETE FROM Chapter'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND chapterIndex>=:minChapterIndex')
  Future<void> deleteByMinChapterIndex(int classroomId, int contentSerial, int minChapterIndex);

  @Query('DELETE FROM Chapter'
      ' WHERE Chapter.classroomId=:classroomId'
      ' and Chapter.contentSerial=:contentSerial')
  Future<void> delete(int classroomId, int contentSerial);

  @Query('DELETE FROM ChapterKey WHERE id=:id')
  Future<void> deleteById(int id);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(List<Chapter> entities);
}
