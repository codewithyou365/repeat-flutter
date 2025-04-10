// dao/lesson_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/lesson.dart';

@dao
abstract class LessonDao {
  @Query('SELECT * FROM Lesson WHERE classroomId=:classroomId and contentSerial=:contentSerial')
  Future<List<Lesson>> find(int classroomId, int contentSerial);

  @Query('DELETE FROM Lesson'
      ' WHERE Lesson.classroomId=:classroomId'
      ' and Lesson.contentSerial=:contentSerial')
  Future<void> delete(int classroomId, int contentSerial);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(List<Lesson> entities);
}
