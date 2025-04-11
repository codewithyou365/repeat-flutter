import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/lock.dart';

@dao
abstract class SegmentKeyDao {
  @Query('SELECT count(id) FROM SegmentKey where classroomId=:classroomId and contentSerial=:contentSerial lessonIndex=:lessonIndex')
  Future<int?> count(int classroomId, int contentSerial, int lessonIndex);
}
