import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment_key.dart';

@dao
abstract class SegmentKeyDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(SegmentKey entity);

  @Query('SELECT * FROM SegmentKey where id=:id')
  Future<SegmentKey?> oneById(int id);

  @Query('SELECT count(id) FROM SegmentKey where classroomId=:classroomId and contentSerial=:contentSerial lessonIndex=:lessonIndex')
  Future<int?> count(int classroomId, int contentSerial, int lessonIndex);

  @Query('SELECT * FROM SegmentKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex=:lessonIndex AND segmentIndex>=:minSegmentIndex')
  Future<List<SegmentKey>> findByMinSegmentIndex(int classroomId, int contentSerial, int lessonIndex, int minSegmentIndex);

  @Query('DELETE FROM SegmentKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex=:lessonIndex AND segmentIndex>=:minSegmentIndex')
  Future<void> deleteByMinSegmentIndex(int classroomId, int contentSerial, int lessonIndex, int minSegmentIndex);

  @Query('SELECT * FROM SegmentKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex>=:minLessonIndex')
  Future<List<SegmentKey>> findByMinLessonIndex(int classroomId, int contentSerial, int minLessonIndex);

  @Query('DELETE FROM SegmentKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex>=:minLessonIndex')
  Future<void> deleteByMinLessonIndex(int classroomId, int contentSerial, int minLessonIndex);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertListOrFail(List<SegmentKey> entities);
}
