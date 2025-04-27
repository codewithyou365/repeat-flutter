import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment_key.dart';

@dao
abstract class SegmentKeyDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(SegmentKey entity);

  @Query('SELECT count(id) FROM SegmentKey where classroomId=:classroomId and contentSerial=:contentSerial lessonIndex=:lessonIndex')
  Future<int?> count(int classroomId, int contentSerial, int lessonIndex);

  @Query('SELECT * FROM SegmentKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex=:lessonIndex AND segmentIndex>=:minSegmentIndex')
  Future<List<SegmentKey>> findByMinSegmentIndex(int classroomId, int contentSerial, int lessonIndex, int minSegmentIndex);

  @Query('DELETE FROM SegmentKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex=:lessonIndex AND segmentIndex>=:minSegmentIndex')
  Future<void> deleteByMinSegmentIndex(int classroomId, int contentSerial, int lessonIndex, int minSegmentIndex);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertListOrFail(List<SegmentKey> entities);
}
