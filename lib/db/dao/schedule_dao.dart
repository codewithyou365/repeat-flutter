// dao/schedule_dao.dart

import 'dart:math';

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';

// Sop : SegmentOverallProgress(Schedule)
// Stp : SegmentTodayProgress(ScheduleCurrent)

@dao
abstract class ScheduleDao {
  static List<int> ebbinghausForgettingCurve = [
    0,
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
  static const int maxLearnCountPerGroup = 1000;
  static int maxRepeatTime = 3;

  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  /// --- currency schedule ---
  @Query('SELECT count(1) FROM SegmentTodayPrg')
  Future<int?> totalSegmentTodayPrg();

  @Query("SELECT * FROM SegmentTodayPrg")
  Future<List<SegmentTodayPrg>> findAllSegmentTodayPrg();

  @Query("SELECT * FROM SegmentTodayPrg limit 1")
  Future<SegmentTodayPrg?> findOneSegmentTodayPrg();

  @Query('DELETE FROM SegmentTodayPrg')
  Future<void> deleteSegmentTodayPrg();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSegmentTodayPrg(List<SegmentTodayPrg> entities);

  @Query('SELECT * FROM SegmentTodayPrg where progress<:maxProgress order by viewTime,sort asc')
  Future<List<SegmentTodayPrg>> findSegmentTodayPrg(int maxProgress);

  @Query("SELECT * FROM SegmentOverallPrg where next<:now order by progress,sort limit :limit")
  Future<List<SegmentOverallPrg>> findSegmentOverallPrg(int limit, DateTime now);

  /// --- error

  @Query('UPDATE SegmentOverallPrg SET progress=:progress,next=:next WHERE `key`=:key')
  Future<void> setSegmentOverallPrg(String key, int progress, DateTime next);

  @Query('UPDATE SegmentTodayPrg SET progress=:progress,viewTime=:viewTime WHERE `key`=:key')
  Future<void> setSegmentTodayPrg(String key, int progress, DateTime viewTime);

  @Query("SELECT * FROM SegmentOverallPrg WHERE `key`=:key")
  Future<SegmentOverallPrg?> getSegmentOverallPrg(String key);

  @Query("SELECT"
      " Segment.`key` `key`"
      ",indexFile.id indexFileId"
      ",mediaFile.id mediaFileId"
      ",Segment.lessonIndex lessonIndex"
      ",Segment.segmentIndex segmentIndex"
      ",indexFile.url indexFileUrl"
      ",indexFile.path indexFilePath"
      ",mediaFile.path mediaFilePath"
      " FROM Segment"
      " JOIN CacheFile indexFile ON indexFile.id=Segment.indexFileId"
      " JOIN CacheFile mediaFile ON mediaFile.id=Segment.mediaFileId"
      " WHERE Segment.`key`=:key")
  Future<SegmentContentInDb?> getSegmentContent(String key);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSegments(List<Segment> entities);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSegmentOverallPrgs(List<SegmentOverallPrg> entities);

  @Query('SELECT `key` FROM Schedule WHERE indexUrl = :indexUrl')
  Future<List<String>> findKeyByUrl(String indexUrl);

  @transaction
  Future<List<SegmentTodayPrg>> initToday() async {
    await forUpdate();
    var now = DateTime.now();

    List<SegmentTodayPrg> tps = <SegmentTodayPrg>[];
    {
      var needToDelete = false;
      var needToInsert = false;
      var tp = await findOneSegmentTodayPrg();
      if (tp == null) {
        needToInsert = true;
      } else if (tp.createTime.compareTo(now.subtract(Duration(seconds: intervalSeconds))) < 0) {
        needToDelete = true;
        needToInsert = true;
      }

      if (needToDelete) {
        await deleteSegmentTodayPrg();
      }

      if (needToInsert) {
        List<SegmentOverallPrg> overall = await findSegmentOverallPrg(findLearnCountPerDay, now);
        for (var element in overall) {
          tps.add(SegmentTodayPrg(element.key, element.sort, 0, DateTime.fromMicrosecondsSinceEpoch(0), DateTime.now()));
        }
        tps.sort((a, b) => a.sort.compareTo(b.sort));
        tps = tps.sublist(0, min(learnCountPerGroup, tps.length));
        await insertSegmentTodayPrg(tps);
      } else {
        tps = await findSegmentTodayPrg(maxRepeatTime);
      }
    }
    return tps;
  }

  @transaction
  Future<void> error(SegmentTodayPrg scheduleCurrent) async {
    await forUpdate();
    var key = scheduleCurrent.key;
    var now = DateTime.now();
    await setSegmentOverallPrg(key, 0, now.add(Duration(seconds: ebbinghausForgettingCurve.first)));
    await setScheduleCurrentWithCache(scheduleCurrent, 0, now);
  }

  @transaction
  Future<void> right(SegmentTodayPrg segmentTodayPrg) async {
    await forUpdate();
    var key = segmentTodayPrg.key;
    var now = DateTime.now();
    bool complete = false;
    if (segmentTodayPrg.progress == 0 && DateTime.fromMicrosecondsSinceEpoch(0).compareTo(segmentTodayPrg.viewTime) == 0) {
      complete = true;
      await setScheduleCurrentWithCache(segmentTodayPrg, maxRepeatTime, now);
    }

    if (segmentTodayPrg.progress + 1 > maxRepeatTime) {
      complete = true;
      await setScheduleCurrentWithCache(segmentTodayPrg, maxRepeatTime, now);
    }
    if (complete) {
      var schedule = await getSegmentOverallPrg(key);
      if (schedule == null) {
        return;
      }
      if (schedule.next.compareTo(now) < 0) {
        if (schedule.progress + 1 >= ebbinghausForgettingCurve.length - 1) {
          await setSegmentOverallPrg(key, schedule.progress + 1, now.add(Duration(seconds: ebbinghausForgettingCurve.last)));
        } else {
          await setSegmentOverallPrg(key, schedule.progress + 1, now.add(Duration(seconds: ebbinghausForgettingCurve[schedule.progress + 1])));
        }
      }
    } else {
      await setScheduleCurrentWithCache(segmentTodayPrg, segmentTodayPrg.progress + 1, now);
    }
  }

  @transaction
  Future<List<SegmentTodayPrg>> clearToday() async {
    await forUpdate();
    var ret = await findAllSegmentTodayPrg();
    await deleteSegmentTodayPrg();
    return ret;
  }

  Future<void> setScheduleCurrentWithCache(SegmentTodayPrg segmentTodayPrg, int progress, DateTime now) async {
    var key = segmentTodayPrg.key;
    await setSegmentTodayPrg(key, progress, now);
    segmentTodayPrg.progress = progress;
    segmentTodayPrg.viewTime = now;
  }
}
