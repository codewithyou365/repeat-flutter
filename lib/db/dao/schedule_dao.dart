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
  static List<int> ebbinghausForgettingCurve = [
    8 * 60 * 60,
    2 * 24 * 60 * 60,
    4 * 24 * 60 * 60,
    7 * 24 * 60 * 60,
    15 * 24 * 60 * 60,
    30 * 24 * 60 * 60,
    3 * 31 * 24 * 60 * 60,
    6 * 31 * 24 * 60 * 60,
    12 * 31 * 24 * 60 * 60,
  ];
  static int intervalSeconds = 8 * 60 * 60;
  static int findLearnCountPerDay = 45;
  static int learnCountPerDay = 30;
  static int learnCountPerGroup = 10;
  static int maxRepeatTime = 3;

  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  /// --- today schedule ---
  @Query("SELECT * FROM ScheduleToday limit 1")
  Future<ScheduleToday?> findOneScheduleToday();

  @Query('DELETE FROM ScheduleToday')
  Future<void> deleteScheduleToday();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertScheduleToday(List<ScheduleToday> entities);

  @Query('SELECT * FROM ScheduleToday order by sort')
  Future<List<ScheduleToday>> findScheduleToday();

  /// --- currency schedule ---
  @Query("SELECT * FROM ScheduleCurrent limit 1")
  Future<ScheduleCurrent?> findOneScheduleCurrent();

  @Query('DELETE FROM ScheduleCurrent')
  Future<void> deleteScheduleCurrent();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertScheduleCurrent(List<ScheduleCurrent> entities);

  @Query('SELECT * FROM ScheduleCurrent order by errorTime desc,sort asc')
  Future<List<ScheduleCurrent>> findScheduleCurrent();

  @Query("SELECT * FROM Schedule where next<datetime('now') order by progress,sort limit :limit")
  Future<List<Schedule>> findSchedule(int limit);

  /// --- error

  @Query('UPDATE Schedule SET progress=:progress,next=:next WHERE `key`=:key')
  Future<void> setSchedule(String key, int progress, DateTime next);

  @Query('UPDATE ScheduleCurrent SET progress=:progress,errorTime=:errorTime WHERE `key`=:key')
  Future<void> setScheduleCurrentForError(String key, int progress, DateTime errorTime);

  @Query('UPDATE ScheduleCurrent SET progress=:progress WHERE `key`=:key')
  Future<void> setScheduleCurrentForRight(String key, int progress);

  @Query("SELECT * FROM Schedule WHERE `key`=:key")
  Future<Schedule?> getOneSchedule(String key);

  @Query("SELECT * FROM ScheduleCurrent WHERE `key`=:key")
  Future<ScheduleCurrent?> getOneScheduleCurrent(String key);

  @delete
  Future<void> deleteOneScheduleCurrent(ScheduleCurrent data);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSchedules(List<Schedule> entities);

  @Query('SELECT `key` FROM Schedule WHERE indexUrl = :indexUrl')
  Future<List<String>> findKeyByUrl(String indexUrl);

  @delete
  Future<void> deleteContentIndex(List<Schedule> data);

  @transaction
  Future<LearnContent> initCurrent() async {
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
      } else if (scheduleToady.fullTime.compareTo(now.subtract(Duration(seconds: intervalSeconds))) < 0) {
        needToDelete = true;
        needToInsert = true;
      }

      if (needToDelete) {
        await deleteScheduleToday();
      }

      if (needToInsert) {
        List<Schedule> schedules = await findSchedule(findLearnCountPerDay);
        for (var element in schedules) {
          schedulesToday.add(ScheduleToday(element.key, element.url, element.sort, now));
        }
        schedulesToday.sort((a, b) => a.sort.compareTo(b.sort));
        await insertScheduleToday(schedulesToday.take(learnCountPerDay).toList());
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
        needToInsert = true;
      }

      if (needToDelete) {
        await deleteScheduleCurrent();
      }

      if (needToInsert) {
        for (int i = 0; i < learnCountPerGroup; ++i) {
          if (i < schedulesToday.length) {
            var element = schedulesToday[i];
            schedulesCurrent.add(ScheduleCurrent(element.key, element.url, element.sort, 0, DateTime.fromMicrosecondsSinceEpoch(0)));
          }
        }
        await insertScheduleCurrent(schedulesCurrent);
      } else {
        schedulesCurrent = await findScheduleCurrent();
      }
    }
    return LearnContent(schedulesToday, schedulesCurrent);
  }

  @transaction
  Future<void> error(String key) async {
    await forUpdate();
    var now = DateTime.now();
    await setSchedule(key, 0, now.add(Duration(seconds: ebbinghausForgettingCurve.first)));
    await setScheduleCurrentForError(key, 0, now);
  }

  @transaction
  Future<void> right(String key) async {
    await forUpdate();
    var now = DateTime.now();
    var scheduleCurrent = await getOneScheduleCurrent(key);
    if (scheduleCurrent == null) {
      return;
    }
    bool complete = false;
    if (scheduleCurrent.progress == 0 && DateTime.fromMicrosecondsSinceEpoch(0).compareTo(scheduleCurrent.errorTime) == 0) {
      complete = true;
      await setScheduleCurrentForRight(key, maxRepeatTime);
    }

    if (scheduleCurrent.progress + 1 > maxRepeatTime) {
      complete = true;
      await setScheduleCurrentForRight(key, maxRepeatTime);
    }
    if (complete) {
      var schedule = await getOneSchedule(key);
      if (schedule == null) {
        return;
      }
      if (schedule.next.compareTo(now) < 0) {
        if (schedule.progress + 1 >= ebbinghausForgettingCurve.length - 1) {
          await setSchedule(key, schedule.progress + 1, now.add(Duration(seconds: ebbinghausForgettingCurve.last)));
        } else {
          await setSchedule(key, schedule.progress + 1, now.add(Duration(seconds: ebbinghausForgettingCurve[schedule.progress + 1])));
        }
      }
    } else {
      await setScheduleCurrentForRight(key, scheduleCurrent.progress + 1);
    }
  }
}
