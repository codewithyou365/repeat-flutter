// dao/schedule_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/schedule.dart';

@dao
abstract class ScheduleDao {
  @Query('SELECT * FROM Schedule WHERE url = :url')
  Future<Schedule?> one(String url);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSchedule(Schedule data);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSchedules(List<Schedule> entities);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateSchedule(Schedule data);

  @Query('UPDATE OR ABORT Schedule SET count=:count,total=:total WHERE url = :url')
  Future<void> updateProgressByUrl(String url, int count, int total);

  @Query('UPDATE OR ABORT Schedule SET count=total,path=:path WHERE url = :url')
  Future<void> updateFinish(String url, String path);
}
