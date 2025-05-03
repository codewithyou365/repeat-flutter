import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment.dart';

@dao
abstract class SegmentDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(Segment entity);

  @Query('SELECT * FROM Segment'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex=:lessonIndex AND segmentIndex=:segmentIndex')
  Future<Segment?> one(int classroomId, int contentSerial, int lessonIndex, int segmentIndex);

  @Query('SELECT * FROM Segment'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex>=:minLessonIndex order by lessonIndex,segmentIndex limit 1')
  Future<Segment?> last(int classroomId, int contentSerial, int minLessonIndex);

  @Query('SELECT * FROM Segment'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex=:lessonIndex AND segmentIndex>=:minSegmentIndex')
  Future<List<Segment>> findByMinSegmentIndex(int classroomId, int contentSerial, int lessonIndex, int minSegmentIndex);

  @Query('DELETE FROM Segment'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex=:lessonIndex AND segmentIndex>=:minSegmentIndex')
  Future<void> deleteByMinSegmentIndex(int classroomId, int contentSerial, int lessonIndex, int minSegmentIndex);

  @Query('SELECT * FROM Segment'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex>=:minLessonIndex')
  Future<List<Segment>> findByMinLessonIndex(int classroomId, int contentSerial, int minLessonIndex);

  @Query('DELETE FROM Segment'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex>=:minLessonIndex')
  Future<void> deleteByMinLessonIndex(int classroomId, int contentSerial, int minLessonIndex);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertListOrFail(List<Segment> entities);
}
