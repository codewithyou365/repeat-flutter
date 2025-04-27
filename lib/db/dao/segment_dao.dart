import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment.dart';

@dao
abstract class SegmentDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(Segment entity);

  @Query('SELECT * FROM Segment'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex=:lessonIndex AND segmentIndex>=:minSegmentIndex')
  Future<List<Segment>> findByMinSegmentIndex(int classroomId, int contentSerial, int lessonIndex, int minSegmentIndex);

  @Query('DELETE FROM Segment'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex=:lessonIndex AND segmentIndex>=:minSegmentIndex')
  Future<void> deleteByMinSegmentIndex(int classroomId, int contentSerial, int lessonIndex, int minSegmentIndex);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertListOrFail(List<Segment> entities);

}
