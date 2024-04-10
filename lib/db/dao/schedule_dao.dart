// dao/schedule_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/schedule.dart';
import 'package:repeat_flutter/db/entity/schedule_today.dart';
import 'package:repeat_flutter/db/entity/schedule_current.dart';

class LearnContent {
  List<ScheduleToday> schedulesToday;
  List<ScheduleCurrent> schedulesCurrent;

  LearnContent(this.schedulesToday, this.schedulesCurrent);
}

@dao
abstract class ScheduleDao {
  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  /// --- today schedule ---
  @Query("SELECT * FROM ScheduleToday limit 1")
  Future<ScheduleToday?> findOneScheduleToday();

  @Query('SELECT `key` FROM ScheduleToday')
  Future<List<String>> findScheduleTodayKey();

  @delete
  Future<void> deleteScheduleToday(List<ScheduleToday> data);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertScheduleToday(List<ScheduleToday> entities);

  @Query('SELECT * FROM ScheduleToday order by sort')
  Future<List<ScheduleToday>> findScheduleToday();

  /// --- currency schedule ---
  @Query("SELECT * FROM ScheduleCurrent limit 1")
  Future<ScheduleCurrent?> findOneScheduleCurrent();

  @Query('SELECT `key` FROM ScheduleCurrent')
  Future<List<String>> findScheduleCurrentKey();

  @delete
  Future<void> deleteScheduleCurrent(List<ScheduleCurrent> data);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertScheduleCurrent(List<ScheduleCurrent> entities);

  @Query('SELECT * FROM ScheduleCurrent order by sort')
  Future<List<ScheduleCurrent>> findScheduleCurrent();

  @Query("SELECT * FROM Schedule where next<datetime('now') order by progress,sort limit :limit")
  Future<List<Schedule>> findSchedule(int limit);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSchedules(List<Schedule> entities);

  @Query('SELECT `key` FROM Schedule WHERE indexUrl = :indexUrl')
  Future<List<String>> findKeyByUrl(String indexUrl);

  @delete
  Future<void> deleteContentIndex(List<Schedule> data);

  @transaction
  Future<LearnContent> initCurrent() async {
    const intervalSeconds = 15;
    const learnCountPerDay = 6;
    const learnCountPerGroup = 2;

    //const intervalSeconds = 8 * 60 * 60;
    //const learnCountPerDay = 30;
    //const learnCountPerGroup = 10;
    await forUpdate();
    var now = DateTime.now();
    var renew = false;
    List<ScheduleToday> schedulesToday = <ScheduleToday>[];
    {
      var needToDelete = false;
      var needToInsert = false;
      var scheduleToady = await findOneScheduleToday();
      if (scheduleToady == null) {
        needToInsert = true;
      } else if (scheduleToady.fullTime.compareTo(now.subtract(const Duration(seconds: intervalSeconds))) < 0) {
        needToDelete = true;
        needToInsert = true;
      }

      if (needToDelete) {
        var keys = await findScheduleTodayKey();
        await deleteScheduleToday(ScheduleToday.create(keys));
      }

      if (needToInsert) {
        List<Schedule> schedules = await findSchedule(learnCountPerDay);
        for (var element in schedules) {
          schedulesToday.add(ScheduleToday(element.key, element.url, element.sort, now));
        }
        await insertScheduleToday(schedulesToday);
      } else {
        schedulesToday = await findScheduleToday();
      }
      renew = needToInsert;
    }

    List<ScheduleCurrent> schedulesCurrent = <ScheduleCurrent>[];
    {
      var needToDelete = false;
      var needToInsert = false;
      var scheduleCurrent = await findOneScheduleCurrent();
      if (scheduleCurrent == null) {
        needToInsert = true;
      } else if (renew) {
        needToDelete = true;
      }

      if (needToDelete) {
        var keys = await findScheduleCurrentKey();
        await deleteScheduleCurrent(ScheduleCurrent.create(keys));
      }

      if (needToInsert) {
        for (int i = 0; i < learnCountPerGroup; ++i) {
          if (i < schedulesToday.length) {
            var element = schedulesToday[i];
            schedulesCurrent.add(ScheduleCurrent(element.key, element.url, element.sort, 0));
          }
        }
        await insertScheduleCurrent(schedulesCurrent);
      } else {
        schedulesCurrent = await findScheduleCurrent();
      }
    }
    return LearnContent(schedulesToday, schedulesCurrent);
  }
}
