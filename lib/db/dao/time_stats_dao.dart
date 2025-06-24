import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/verse_stats.dart';
import 'package:repeat_flutter/db/entity/time_stats.dart';

@dao
abstract class TimeStatsDao {
  @Query('DELETE FROM TimeStats WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('SELECT * FROM TimeStats WHERE classroomId = :classroomId AND createDate = :date')
  Future<TimeStats?> getByDate(int classroomId, Date date);

  @Query('SELECT * FROM TimeStats WHERE classroomId = :classroomId AND createDate >= :start AND createDate <= :end')
  Future<List<TimeStats>> getTimeStatsByDateRange(int classroomId, Date start, Date end);

  @Query('SELECT COALESCE(sum(duration), 0) FROM TimeStats WHERE classroomId = :classroomId AND createDate >= :start AND createDate <= :end')
  Future<int?> getTimeByDateRange(int classroomId, Date start, Date end);

  @Query('UPDATE TimeStats set duration=:time+duration'
      ' WHERE classroomId=:classroomId AND createDate=:date')
  Future<void> update(int classroomId, Date date, int time);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrReplace(TimeStats timeStats);

  @transaction
  Future<void> tryInsert(TimeStats newTimeStats) async {
    var oldTimeStats = await getByDate(newTimeStats.classroomId, newTimeStats.createDate);
    if (oldTimeStats == null) {
      insertOrReplace(newTimeStats);
    }
  }
}
