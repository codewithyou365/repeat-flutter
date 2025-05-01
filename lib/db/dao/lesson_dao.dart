// dao/lesson_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/lesson.dart';

@dao
abstract class LessonDao {
  @Query('SELECT * FROM Lesson WHERE classroomId=:classroomId and contentSerial=:contentSerial')
  Future<List<Lesson>> find(int classroomId, int contentSerial);

  @Query('SELECT * FROM Lesson WHERE classroomId=:classroomId and contentSerial=:contentSerial and lessonIndex=:lessonIndex')
  Future<Lesson?> one(int classroomId, int contentSerial, int lessonIndex);

  @Query('SELECT * FROM Lesson'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex>=:minLessonIndex')
  Future<List<Lesson>> findByMinLessonIndex(int classroomId, int contentSerial, int minLessonIndex);

  @Query('DELETE FROM Lesson'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex>=:minLessonIndex')
  Future<void> deleteByMinLessonIndex(int classroomId, int contentSerial, int minLessonIndex);

  @Query('DELETE FROM Lesson'
      ' WHERE Lesson.classroomId=:classroomId'
      ' and Lesson.contentSerial=:contentSerial')
  Future<void> delete(int classroomId, int contentSerial);

  @Query('DELETE FROM LessonKey WHERE id=:id')
  Future<void> deleteById(int id);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(List<Lesson> entities);
}
