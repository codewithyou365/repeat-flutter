// dao/schedule_dao.dart

import 'dart:math';

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
import 'package:repeat_flutter/db/entity/segment.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';
import 'package:repeat_flutter/db/entity/segment_review.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';

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
  static var review = [3 * 24 * 60 * 60, 3 * 24 * 60 * 60];
  static int intervalSeconds = 8 * 60 * 60;
  static int findLearnCountPerDay = 45;
  static int learnCountPerDay = 4;
  static int learnCountPerGroup = 2;
  static const int maxLearnCountPerGroup = 1000;
  static int maxRepeatTime = 3;

  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  @delete
  Future<void> deleteContentIndex(ContentIndex data);

  @delete
  Future<void> deleteSegments(List<Segment> data);

  @Query('SELECT path FROM Doc WHERE url = :url')
  Future<String?> getDoc(String url);

  /// --- SegmentTodayPrg ---

  @Query('SELECT count(1) FROM SegmentTodayPrg')
  Future<int?> totalSegmentTodayPrg();

  @Query("SELECT `key` FROM SegmentTodayPrg")
  Future<List<String>> findAllSegmentTodayPrg();

  @Query("SELECT * FROM SegmentTodayPrg limit 1")
  Future<SegmentTodayPrg?> findOneSegmentTodayPrg();

  @Query('DELETE FROM SegmentTodayPrg')
  Future<void> deleteSegmentTodayPrg();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSegmentTodayPrg(List<SegmentTodayPrg> entities);

  @Query('SELECT * FROM SegmentTodayPrg where progress<:maxProgress order by viewTime,sort asc')
  Future<List<SegmentTodayPrg>> findSegmentTodayPrg(int maxProgress);

  @Query('UPDATE SegmentTodayPrg SET progress=:progress,viewTime=:viewTime WHERE `key`=:key')
  Future<void> setSegmentTodayPrg(String key, int progress, DateTime viewTime);

  @Query("SELECT count(1) FROM SegmentReview"
      " JOIN SegmentOverallPrg ON SegmentOverallPrg.`key` = SegmentReview.`key`"
      " JOIN Segment ON Segment.`key` = SegmentReview.`key`"
      " WHERE SegmentReview.createDate=:now")
  Future<int?> findLearnedCount(Date now);

  @Query("SELECT SegmentOverallPrg.* FROM SegmentReview"
      " JOIN SegmentOverallPrg ON SegmentOverallPrg.`key` = SegmentReview.`key`"
      " JOIN Segment ON Segment.`key` = SegmentReview.`key`"
      " WHERE SegmentReview.createDate=:now")
  Future<List<SegmentOverallPrg>> findLearned(Date now);

  @Query("SELECT Segment.*"
      " FROM SegmentOverallPrg"
      " JOIN Segment ON Segment.`key` = SegmentOverallPrg.`key`"
      " where SegmentOverallPrg.next<:now order by SegmentOverallPrg.progress limit :limit")
  Future<List<Segment>> scheduleToday(int limit, DateTime now);

  @Query("SELECT count(1) FROM SegmentOverallPrg"
      " JOIN Segment ON Segment.`key` = SegmentOverallPrg.`key`"
      " where next<:now order by progress,sort limit :limit")
  Future<int?> findSegmentOverallPrgCount(int limit, DateTime now);

  /// --- error

  @Query('UPDATE SegmentOverallPrg SET progress=:progress,next=:next WHERE `key`=:key')
  Future<void> setSegmentOverallPrg(String key, int progress, DateTime next);

  @Query("SELECT * FROM SegmentOverallPrg WHERE `key`=:key")
  Future<SegmentOverallPrg?> getSegmentOverallPrg(String key);

  /// --- SegmentReview
  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertSegmentReview(List<SegmentReview> review);

  @Query("SELECT `key` FROM SegmentReview on SegmentReview.createTime=:now")
  Future<List<String>> findTodaySegmentReview(int now);

  @Query("SELECT"
      " Segment.`key` `key`"
      ",indexDoc.id indexDocId"
      ",mediaDoc.id mediaDocId"
      ",Segment.lessonIndex lessonIndex"
      ",Segment.segmentIndex segmentIndex"
      ",Segment.sort sort"
      ",indexDoc.url indexDocUrl"
      ",indexDoc.path indexDocPath"
      ",mediaDoc.path mediaDocPath"
      " FROM Segment"
      " JOIN Doc indexDoc ON indexDoc.id=Segment.indexDocId"
      " JOIN Doc mediaDoc ON mediaDoc.id=Segment.mediaDocId"
      " WHERE Segment.`key`=:key")
  Future<SegmentContentInDb?> getSegmentContent(String key);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSegments(List<Segment> entities);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertSegmentOverallPrgs(List<SegmentOverallPrg> entities);

  @Query('SELECT `key` FROM Schedule WHERE indexUrl = :indexUrl')
  Future<List<String>> findKeyByUrl(String indexUrl);

  /// for manager
  @transaction
  Future<void> importSegment(List<Segment> segments, List<SegmentOverallPrg> segmentOverallPrgs) async {
    await forUpdate();
    await insertSegments(segments);
    await insertSegmentOverallPrgs(segmentOverallPrgs);
  }

  @transaction
  Future<void> deleteContent(String url, List<Segment> segments) async {
    await forUpdate();
    await deleteContentIndex(ContentIndex(url, 0));
    await deleteSegments(segments);
  }

  /// for progress

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
        List<SegmentOverallPrg> learned = await findLearned(Date.from(now));
        if (learned.length >= learnCountPerDay) {
          return [];
        }
        List<Segment> tss = await scheduleToday(findLearnCountPerDay, now);
        for (var ts in tss) {
          tps.add(SegmentTodayPrg(ts.key, ts.sort, 0, DateTime.fromMicrosecondsSinceEpoch(0), DateTime.now()));
        }

        tps.sort((a, b) => a.sort.compareTo(b.sort));
        tps = tps.sublist(0, min(min(learnCountPerGroup, tps.length), learnCountPerDay - learned.length));
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
  Future<List<String>> finishCurrent() async {
    await forUpdate();
    var ret = await findAllSegmentTodayPrg();
    await deleteSegmentTodayPrg();
    await insertSegmentReview(SegmentReview.from(ret));
    return ret;
  }

  Future<void> setScheduleCurrentWithCache(SegmentTodayPrg segmentTodayPrg, int progress, DateTime now) async {
    var key = segmentTodayPrg.key;
    await setSegmentTodayPrg(key, progress, now);
    segmentTodayPrg.progress = progress;
    segmentTodayPrg.viewTime = now;
  }
}
