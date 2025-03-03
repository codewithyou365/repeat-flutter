import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/segment_stats.dart';
import 'package:repeat_flutter/db/entity/time_stats.dart';

@dao
abstract class StatsDao {
  @Query('SELECT * FROM SegmentStats WHERE classroomId = :classroomId AND createDate = :date')
  Future<List<SegmentStats>> getStatsByDate(int classroomId, Date date);

  @Query('SELECT * FROM SegmentStats WHERE classroomId = :classroomId AND createDate >= :start AND createDate <= :end')
  Future<List<SegmentStats>> getStatsByDateRange(int classroomId, Date start, Date end);

  @Query('SELECT COALESCE(COUNT(*), 0) FROM SegmentStats WHERE classroomId = :classroomId AND createDate >= :start AND createDate <= :end')
  Future<int?> getCountByDateRange(int classroomId, Date start, Date end);

  @Query('SELECT COUNT(*) FROM SegmentStats WHERE classroomId = :classroomId AND type = :type AND createDate = :date')
  Future<int?> getCountByType(int classroomId, int type, Date date);

  @Query('SELECT DISTINCT segmentKeyId FROM SegmentStats WHERE classroomId = :classroomId AND createDate = :date')
  Future<List<int>> getDistinctSegmentKeyIds(int classroomId, Date date);

  @Query('SELECT * FROM TimeStats WHERE classroomId = :classroomId AND createDate = :date')
  Future<TimeStats?> getTimeStatsByDate(int classroomId, Date date);

  @Query('SELECT * FROM TimeStats WHERE classroomId = :classroomId AND createDate >= :start AND createDate <= :end')
  Future<List<TimeStats>> getTimeStatsByDateRange(int classroomId, Date start, Date end);

  @Query('SELECT COALESCE(sum(duration), 0) FROM TimeStats WHERE classroomId = :classroomId AND createDate >= :start AND createDate <= :end')
  Future<int?> getTimeByDateRange(int classroomId, Date start, Date end);

  @Query('UPDATE TimeStats set duration=:time+duration'
      ' WHERE classroomId=:classroomId AND createDate=:date')
  Future<void> updateTimeStats(int classroomId, Date date, int time);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertTimeStats(TimeStats timeStats);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertKv(CrKv kv);

  @Query("SELECT CAST(value as INTEGER) FROM CrKv WHERE classroomId=:classroomId and k=:k")
  Future<int?> intKv(int classroomId, CrK k);

  @transaction
  Future<void> tryInsertTimeStats(TimeStats newTimeStats) async {
    var oldTimeStats = await getTimeStatsByDate(newTimeStats.classroomId, newTimeStats.createDate);
    if (oldTimeStats == null) {
      insertTimeStats(newTimeStats);
    }
  }

  @transaction
  Future<List<int>> collectAll() async {
    // utc maybe change, so use before2
    var before2 = DateTime.now().subtract(const Duration(days: 2));
    var before2Date = Date.from(before2);
    int totalLearning;
    var lastRecordCreateDate4StatsTotalLearning = await intKv(Classroom.curr, CrK.lastRecordCreateDate4StatsTotalLearning) ?? 0;
    if (lastRecordCreateDate4StatsTotalLearning < before2Date.value) {
      var lastTotalLearning = await intKv(Classroom.curr, CrK.statsTotalLearning) ?? 0;
      var currLearningStats = await getCountByDateRange(Classroom.curr, Date(lastRecordCreateDate4StatsTotalLearning), before2Date) ?? 0;
      totalLearning = lastTotalLearning + currLearningStats;
      insertKv(CrKv(Classroom.curr, CrK.statsTotalLearning, totalLearning.toString()));
      insertKv(CrKv(Classroom.curr, CrK.lastRecordCreateDate4StatsTotalLearning, before2Date.value.toString()));
    } else {
      totalLearning = await intKv(Classroom.curr, CrK.statsTotalLearning) ?? 0;
    }

    int totalTime;
    var lastRecordCreateDate4StatsTotalTime = await intKv(Classroom.curr, CrK.lastRecordCreateDate4StatsTotalTime) ?? 0;
    if (lastRecordCreateDate4StatsTotalTime < before2Date.value) {
      var lastTotalTime = await intKv(Classroom.curr, CrK.statsTotalTime) ?? 0;
      var currTimeStats = await getTimeByDateRange(Classroom.curr, Date(lastRecordCreateDate4StatsTotalTime), before2Date) ?? 0;
      totalTime = lastTotalTime + currTimeStats;
      insertKv(CrKv(Classroom.curr, CrK.statsTotalTime, totalTime.toString()));
      insertKv(CrKv(Classroom.curr, CrK.lastRecordCreateDate4StatsTotalTime, before2Date.value.toString()));
    } else {
      totalTime = await intKv(Classroom.curr, CrK.statsTotalTime) ?? 0;
    }

    var yesterdayDate = Date.from(DateTime.now().subtract(const Duration(days: 1)));
    List<int> yesterday = [];
    if (lastRecordCreateDate4StatsTotalLearning < yesterdayDate.value || lastRecordCreateDate4StatsTotalTime < yesterdayDate.value) {
      yesterday = await collectDate(yesterdayDate);
    }
    if (lastRecordCreateDate4StatsTotalLearning < yesterdayDate.value) {
      totalLearning = totalLearning + yesterday[0];
    }
    if (lastRecordCreateDate4StatsTotalTime < yesterdayDate.value) {
      totalTime = totalTime + yesterday[1];
    }
    var todayDate = Date.from(DateTime.now());
    List<int> today = [];
    today = await collectDate(todayDate);
    if (lastRecordCreateDate4StatsTotalLearning < todayDate.value) {
      totalLearning = totalLearning + today[0];
    }
    if (lastRecordCreateDate4StatsTotalTime < todayDate.value) {
      totalTime = totalTime + today[1];
    }
    return [today[0], totalLearning, today[1], totalTime];
  }

  Future<List<int>> collectDate(Date date) async {
    int todayTime = await getTimeByDateRange(Classroom.curr, date, date) ?? 0;
    int todayLearning = await getCountByDateRange(Classroom.curr, date, date) ?? 0;
    return [todayLearning, todayTime];
  }
}
