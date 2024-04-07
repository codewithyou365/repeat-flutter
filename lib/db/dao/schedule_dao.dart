// dao/schedule_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/schedule.dart';

@dao
abstract class ScheduleDao {
  @Query("SELECT * FROM Schedule where next<datetime('now') order by progress,sort limit :limit")
  Future<List<Schedule>> findSchedule(int limit);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSchedules(List<Schedule> entities);

  @Query('SELECT * FROM Schedule WHERE url = :url')
  Future<List<Schedule>> findScheduleByUrl(String url);

  @delete
  Future<void> deleteContentIndex(List<Schedule> data);
}
