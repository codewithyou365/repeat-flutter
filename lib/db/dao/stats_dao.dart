import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/verse_stats.dart';
import 'package:repeat_flutter/logic/model/verse_stats_count.dart';

@dao
abstract class StatsDao {
  late AppDatabase db;

  @Query('SELECT * FROM VerseStats WHERE classroomId = :classroomId AND createDate = :date')
  Future<List<VerseStats>> getStatsByDate(int classroomId, Date date);

  @Query('SELECT * FROM VerseStats WHERE classroomId = :classroomId AND createDate >= :start AND createDate <= :end')
  Future<List<VerseStats>> getStatsByDateRange(int classroomId, Date start, Date end);

  /// 日历/趋势图用这个，别用 [getStatsByDateRange] —— 那个会把区间内每一条原始记录
  /// 都反序列化成对象，一个重度用户几个月就是上万行，进页面直接卡帧。
  @Query('SELECT createDate, type, COUNT(1) cnt FROM VerseStats'
      ' WHERE classroomId = :classroomId AND createDate >= :start AND createDate <= :end'
      ' GROUP BY createDate, type')
  Future<List<VerseStatsCount>> getStatsCountByDateRange(int classroomId, Date start, Date end);

  @Query('SELECT COALESCE(COUNT(*), 0) FROM VerseStats WHERE classroomId = :classroomId AND createDate >= :start AND createDate <= :end')
  Future<int?> getCountByDateRange(int classroomId, Date start, Date end);

  @Query('SELECT COUNT(*) FROM VerseStats WHERE classroomId = :classroomId AND type = :type AND createDate = :date')
  Future<int?> getCountByType(int classroomId, int type, Date date);

  @Query('SELECT DISTINCT verseId FROM VerseStats WHERE classroomId = :classroomId AND createDate = :date')
  Future<List<int>> getDistinctVerseKeyIds(int classroomId, Date date);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertKv(CrKv kv);

  @Query("SELECT CAST(value as INTEGER) FROM CrKv WHERE classroomId=:classroomId and k=:k")
  Future<int?> intKv(int classroomId, CrK k);

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
      // 必须 await：不 await 的话写入可能落在事务提交之后，缓存写不进去，
      // 于是每次进统计页都要重新 COUNT 一遍全部历史。
      await insertKv(CrKv(Classroom.curr, CrK.statsTotalLearning, totalLearning.toString()));
      await insertKv(CrKv(Classroom.curr, CrK.lastRecordCreateDate4StatsTotalLearning, before2Date.value.toString()));
    } else {
      totalLearning = await intKv(Classroom.curr, CrK.statsTotalLearning) ?? 0;
    }

    int totalTime;
    var lastRecordCreateDate4StatsTotalTime = await intKv(Classroom.curr, CrK.lastRecordCreateDate4StatsTotalTime) ?? 0;
    if (lastRecordCreateDate4StatsTotalTime < before2Date.value) {
      var lastTotalTime = await intKv(Classroom.curr, CrK.statsTotalTime) ?? 0;
      var currTimeStats = await db.timeStatsDao.getTimeByDateRange(Classroom.curr, Date(lastRecordCreateDate4StatsTotalTime), before2Date) ?? 0;
      totalTime = lastTotalTime + currTimeStats;
      await insertKv(CrKv(Classroom.curr, CrK.statsTotalTime, totalTime.toString()));
      await insertKv(CrKv(Classroom.curr, CrK.lastRecordCreateDate4StatsTotalTime, before2Date.value.toString()));
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
    int todayTime = await db.timeStatsDao.getTimeByDateRange(Classroom.curr, date, date) ?? 0;
    int todayLearning = await getCountByDateRange(Classroom.curr, date, date) ?? 0;
    return [todayLearning, todayTime];
  }
}
