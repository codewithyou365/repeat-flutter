import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/entity/segment_stats.dart';

@dao
abstract class StatsDao {
  @Query('SELECT * FROM SegmentStats WHERE classroomId = :classroomId AND createDate = :date')
  Future<List<SegmentStats>> getStatsByDate(int classroomId, Date date);

  @Query('SELECT * FROM SegmentStats WHERE classroomId = :classroomId AND createDate >= :start AND createDate <= :end')
  Future<List<SegmentStats>> getStatsByDateRange(int classroomId, Date start, Date end);

  @Query('SELECT COUNT(*) FROM SegmentStats WHERE classroomId = :classroomId AND type = :type AND createDate = :date')
  Future<int?> getCountByType(int classroomId, int type, Date date);

  @Query('SELECT DISTINCT segmentKeyId FROM SegmentStats WHERE classroomId = :classroomId AND createDate = :date')
  Future<List<int>> getDistinctSegmentKeyIds(int classroomId, Date date);
}
