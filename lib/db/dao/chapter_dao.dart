// dao/chapter_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/chapter.dart';

@dao
abstract class ChapterDao {
  @Query('SELECT * FROM Chapter WHERE bookId=:bookId')
  Future<List<Chapter>> find(int bookId);

  @Query('SELECT * FROM Chapter WHERE bookId=:bookId and chapterIndex=:chapterIndex')
  Future<Chapter?> one(int bookId, int chapterIndex);

  @Query('SELECT * FROM Chapter WHERE chapterKeyId=:chapterKeyId')
  Future<Chapter?> getById(int chapterKeyId);

  @Query('SELECT count(1) FROM Chapter'
      ' WHERE bookId=:bookId')
  Future<int?> count(int bookId);

  @Query('SELECT * FROM Chapter'
      ' WHERE bookId=:bookId AND chapterIndex>=:minChapterIndex')
  Future<List<Chapter>> findByMinChapterIndex(int bookId, int minChapterIndex);

  @Query('DELETE FROM Chapter'
      ' WHERE bookId=:bookId AND chapterIndex>=:minChapterIndex')
  Future<void> deleteByMinChapterIndex(int bookId, int minChapterIndex);

  @Query('DELETE FROM Chapter'
      ' WHERE Chapter.bookId=:bookId')
  Future<void> delete(int bookId);

  @Query('DELETE FROM Chapter'
      ' WHERE Chapter.classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('DELETE FROM Chapter WHERE chapterKeyId=:chapterKeyId')
  Future<void> deleteByChapterKeyId(int chapterKeyId);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(List<Chapter> entities);
}
