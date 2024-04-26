// dao/schedule_dao.dart

import 'dart:math';

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/num.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/db/entity/segment.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';
import 'package:repeat_flutter/db/entity/segment_review.dart';
import 'package:repeat_flutter/db/entity/segment_current_prg.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/entity/segment_today_review.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/logic/model/segment_review_content.dart';

@dao
abstract class ScheduleDao {
  static List<int> ebbinghausForgettingCurve = [
    0,
    12 * 60 * 60,
    2 * 24 * 60 * 60,
    4 * 24 * 60 * 60,
    7 * 24 * 60 * 60,
    15 * 24 * 60 * 60,
    30 * 24 * 60 * 60,
    3 * 31 * 24 * 60 * 60,
    6 * 31 * 24 * 60 * 60,
    12 * 31 * 24 * 60 * 60,
  ];

  static int intervalSeconds = ebbinghausForgettingCurve[1];
  static int findLearnCountPerDay = 45;
  static int learnCountPerDay = 4;
  static int learnCountPerGroup = 2;
  static const int maxLearnCountPerGroup = 1000;
  static int maxRepeatTime = 3;

  static List<int> review = [3 * 24 * 60 * 60, 7 * 24 * 60 * 60];

  static int reviewMaxCount = learnCountPerDay * review.length;

  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  @delete
  Future<void> deleteContentIndex(ContentIndex data);

  @delete
  Future<void> deleteSegments(List<Segment> data);

  @Query('SELECT path FROM Doc WHERE url = :url')
  Future<String?> getDoc(String url);

  /// --- SegmentCurrentPrg ---

  @Query('SELECT count(1) FROM SegmentCurrentPrg where learnOrReview=:learnOrReview')
  Future<int?> totalSegmentCurrentPrg(bool learnOrReview);

  @Query("SELECT * FROM SegmentCurrentPrg")
  Future<List<SegmentCurrentPrg>> findAllSegmentCurrentPrg();

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertKv(Kv kv);

  @delete
  Future<void> deleteKv(Kv kv);

  @Query("SELECT CAST(value as INTEGER) FROM Kv WHERE `key`=:key")
  Future<int?> value(K key);

  @Query("SELECT * FROM SegmentCurrentPrg where learnOrReview=:learnOrReview limit 1")
  Future<SegmentCurrentPrg?> findOneSegmentCurrentPrg(bool learnOrReview);

  @Query('DELETE FROM SegmentCurrentPrg')
  Future<void> deleteSegmentCurrentPrg();

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertSegmentCurrentPrg(List<SegmentCurrentPrg> entities);

  @Query('SELECT * FROM SegmentCurrentPrg where learnOrReview=:learnOrReview and progress<:maxProgress order by viewTime,sort asc')
  Future<List<SegmentCurrentPrg>> findSegmentCurrentPrg(bool learnOrReview, int maxProgress);

  @Query('SELECT SegmentCurrentPrg.* FROM SegmentCurrentPrg'
      " JOIN (SELECT `key`"
      "  ,max(SegmentTodayReview.finish) finish"
      "  FROM SegmentTodayReview"
      "  WHERE SegmentTodayReview.count=:reviewCount"
      "  group by SegmentTodayReview.key"
      " ) SegmentReviewKey ON SegmentReviewKey.`key` = SegmentCurrentPrg.`key`"
      " AND SegmentReviewKey.finish=0"
      ' where learnOrReview=:learnOrReview order by viewTime,sort asc')
  Future<List<SegmentCurrentPrg>> findSegmentCurrentPrgWithReview(bool learnOrReview, int reviewCount);

  @Query('UPDATE SegmentCurrentPrg SET progress=:progress,viewTime=:viewTime WHERE `key`=:key and learnOrReview=:learnOrReview')
  Future<void> setSegmentCurrentPrg(String key, bool learnOrReview, int progress, DateTime viewTime);

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

  @Query('DELETE FROM SegmentTodayReview')
  Future<void> deleteSegmentTodayReview();

  @Query("SELECT SegmentReview.* FROM SegmentTodayReview"
      " JOIN SegmentReview ON SegmentReview.createDate = SegmentTodayReview.createDate"
      "  ANd SegmentReview.`key` = SegmentTodayReview.`key`"
      " JOIN Segment ON Segment.`key` = SegmentReview.`key`"
      " WHERE SegmentTodayReview.createDate=:now"
      " AND SegmentTodayReview.count=:count")
  Future<List<SegmentReview>> findReviewed(Date now, int count);

  @Query("SELECT * FROM SegmentTodayReview WHERE SegmentTodayReview.finish=false limit 1")
  Future<SegmentTodayReview?> findTodayReviewUnfinished();

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertSegmentTodayReview(List<SegmentTodayReview> review);

  @Query('UPDATE SegmentTodayReview SET finish=1 WHERE createDate in (:createDate) and `key`=:key')
  Future<void> setSegmentTodayReviewFinish(List<Date> createDate, String key);

  @Query("SELECT ifnull(min(createDate),-1) FROM SegmentReview"
      " JOIN Segment ON Segment.`key` = SegmentReview.`key`"
      " WHERE SegmentReview.count=:reviewCount"
      " and SegmentReview.createDate<=:now"
      " order by createDate")
  Future<int?> findReviewedMinCreateDate(int reviewCount, Date now);

  @Query("SELECT Segment.key"
      ",Segment.sort"
      ",SegmentReviewKey.createDate reviewCreateDate"
      ",SegmentReviewKey.count reviewCount"
      " FROM Segment"
      " JOIN (SELECT `key`"
      "  ,group_concat(createDate) createDate"
      "  ,min(SegmentReview.count) count"
      "  FROM SegmentReview"
      "  WHERE SegmentReview.count=:reviewCount"
      "  and SegmentReview.createDate>=:minCreateDate"
      "  group by SegmentReview.key"
      "  limit :limit) SegmentReviewKey on SegmentReviewKey.`key`=Segment.`key`"
      " order by sort")
  Future<List<SegmentReviewContentInDb>> scheduleReviewToday(int reviewCount, int minCreateDate, int limit);

  @Query("SELECT Segment.key"
      ",Segment.sort"
      ",'0' reviewCreateDate"
      ",0 reviewCount"
      " FROM SegmentOverallPrg"
      " JOIN Segment ON Segment.`key` = SegmentOverallPrg.`key`"
      " where SegmentOverallPrg.next<:now order by SegmentOverallPrg.progress limit :limit")
  Future<List<SegmentReviewContentInDb>> scheduleLearnToday(int limit, DateTime now);

  @Query("SELECT count(1) FROM SegmentOverallPrg"
      " JOIN Segment ON Segment.`key` = SegmentOverallPrg.`key`"
      " where next<:now order by progress,sort limit :limit")
  Future<int?> findSegmentOverallPrgCount(int limit, DateTime now);

  @Query('UPDATE SegmentOverallPrg SET progress=:progress,next=:next WHERE `key`=:key')
  Future<void> setSegmentOverallPrg(String key, int progress, DateTime next);

  @Query("SELECT * FROM SegmentOverallPrg WHERE `key`=:key")
  Future<SegmentOverallPrg?> getSegmentOverallPrg(String key);

  /// --- SegmentReview
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertSegmentReview(List<SegmentReview> review);

  @Query('UPDATE SegmentReview SET count=:count WHERE createDate in (:createDate) and `key`=:key')
  Future<void> setSegmentReviewCount(List<Date> createDate, String key, int count);

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
  Future<List<SegmentCurrentPrg>> initToday(Map<String, List<SegmentTodayReview>>? forReview) async {
    await forUpdate();
    var now = DateTime.now();
    var learnOrReview = true;
    if (forReview != null) {
      learnOrReview = false;
    }
    var needInsertToday = [false];
    List<SegmentCurrentPrg> tps = <SegmentCurrentPrg>[];
    {
      var needToDelete = false;
      var needToInsert = false;
      var todayLearnCreateTime = await value(K.todayLearnCreateTime);
      if (todayLearnCreateTime != null && DateTime.fromMillisecondsSinceEpoch(todayLearnCreateTime).compareTo(now.subtract(Duration(seconds: intervalSeconds))) < 0) {
        needToDelete = true;
        needToInsert = true;
      } else {
        var tp = await findOneSegmentCurrentPrg(learnOrReview);
        if (tp == null) {
          needToInsert = true;
        }
      }

      if (needToDelete) {
        await deleteKv(Kv(K.todayLearnCreateTime, ""));
        await deleteSegmentCurrentPrg();
        await deleteSegmentTodayReview();
      }

      if (needToInsert) {
        List<SegmentReviewContentInDb> tss = [];
        if (learnOrReview) {
          tss = await forLearnInsert(now);
        } else {
          tss = await forReviewInsert(now, forReview!, needInsertToday);
        }
        if (tss.isEmpty) {
          return [];
        }
        for (var ts in tss) {
          tps.add(SegmentCurrentPrg(ts.key, learnOrReview, ts.sort, 0, DateTime.fromMicrosecondsSinceEpoch(0)));
        }
        await insertSegmentCurrentPrg(tps);
      } else {
        if (learnOrReview) {
          tps = await findSegmentCurrentPrg(learnOrReview, maxRepeatTime);
        } else {
          tps = await findSegmentCurrentPrg(learnOrReview, maxRepeatTime);
          await forReviewInsert(now, forReview!, needInsertToday);
        }
      }
    }
    if (needInsertToday[0]) {
      List<SegmentTodayReview> todayReviews = [];
      if (forReview!.isNotEmpty) {
        forReview.forEach((key, value) {
          todayReviews.addAll(value);
        });
        todayReviews.sort((a, b) {
          if (a.createDate != b.createDate) {
            return a.createDate.value.compareTo(b.createDate.value);
          } else {
            return a.key.compareTo(b.key);
          }
        });
        await insertSegmentTodayReview(todayReviews);
      }
    }
    return tps;
  }

  // String getSegmentCurrentPrgKey(String key, bool learnOrReview) {
  //   if (learnOrReview) {
  //     return "+$key";
  //   } else {
  //     return "-$key";
  //   }
  // }

  Future<List<SegmentReviewContentInDb>> forLearnInsert(DateTime now) async {
    List<SegmentOverallPrg> learned = await findLearned(Date.from(now));
    if (learned.length >= learnCountPerDay) {
      return [];
    }
    List<SegmentReviewContentInDb> tss = await scheduleLearnToday(findLearnCountPerDay, now);
    tss.sort((a, b) => a.sort.compareTo(b.sort));
    tss = tss.sublist(0, min(min(learnCountPerGroup, tss.length), learnCountPerDay - learned.length));
    return tss;
  }

  Future<List<SegmentReviewContentInDb>> forReviewInsert(
    DateTime now,
    Map<String, List<SegmentTodayReview>> keyToCreateDate,
    List<bool> needInsertToday,
  ) async {
    int? needReviewLevel;
    SegmentTodayReview? todayReviewUnfinished = await findTodayReviewUnfinished();
    if (todayReviewUnfinished == null) {
      needInsertToday[0] = true;
    } else {
      needInsertToday[0] = false;
      needReviewLevel = todayReviewUnfinished.count;
    }
    for (int i = review.length - 1; i >= 0; --i) {
      if (needReviewLevel != null && i != needReviewLevel) {
        continue;
      }
      var minCreateDate = await findReviewedMinCreateDate(i, Date.from(now.subtract(Duration(seconds: review[i]))));
      if (minCreateDate == null || minCreateDate == -1) {
        continue;
      }
      List<SegmentReview> reviewed = await findReviewed(Date.from(now), i);
      if (reviewMaxCount - reviewed.length <= 0) {
        continue;
      }
      List<SegmentReviewContentInDb> tss = await scheduleReviewToday(i, minCreateDate, reviewMaxCount - reviewed.length);
      if (tss.isEmpty) {
        continue;
      }
      for (var r in tss) {
        var dates = Num.toInts(r.reviewCreateDate);
        List<SegmentTodayReview> value = [];
        for (var date in dates) {
          value.add(SegmentTodayReview(Date(date), r.key, r.reviewCount, false));
        }
        keyToCreateDate[r.key] = value;
      }
      return tss;
    }

    return [];
  }

  @transaction
  Future<void> error(SegmentCurrentPrg scheduleCurrent, List<SegmentTodayReview> reviews) async {
    await forUpdate();
    var learnOrReview = reviews.isEmpty;
    var key = scheduleCurrent.key;
    var now = DateTime.now();
    await insertKv(Kv(K.todayLearnCreateTime, "${now.millisecondsSinceEpoch}"));
    await setSegmentOverallPrg(key, 0, now.add(Duration(seconds: intervalSeconds)));
    await setScheduleCurrentWithCache(scheduleCurrent, learnOrReview, 0, now);
  }

  @transaction
  Future<void> right(SegmentCurrentPrg segmentTodayPrg, List<SegmentTodayReview> reviews) async {
    await forUpdate();
    var learnOrReview = reviews.isEmpty;
    var key = segmentTodayPrg.key;
    var now = DateTime.now();
    await insertKv(Kv(K.todayLearnCreateTime, "${now.millisecondsSinceEpoch}"));
    bool complete = false;
    if (segmentTodayPrg.progress == 0 && DateTime.fromMicrosecondsSinceEpoch(0).compareTo(segmentTodayPrg.viewTime) == 0) {
      complete = true;
      await setScheduleCurrentWithCache(segmentTodayPrg, learnOrReview, maxRepeatTime, now);
    }

    if (segmentTodayPrg.progress + 1 >= maxRepeatTime) {
      complete = true;
      await setScheduleCurrentWithCache(segmentTodayPrg, learnOrReview, maxRepeatTime, now);
    }
    if (complete) {
      if (reviews.isNotEmpty) {
        List<Date> createDates = reviews.map((e) => e.createDate).toList();
        await setSegmentReviewCount(createDates, key, reviews.first.count + 1);
        await setSegmentTodayReviewFinish(createDates, key);
      } else {
        var schedule = await getSegmentOverallPrg(key);
        if (schedule == null) {
          return;
        }
        await insertSegmentReview([SegmentReview(Date.from(now), key, 0)]);
        if (schedule.next.compareTo(now) < 0) {
          if (schedule.progress + 1 >= ebbinghausForgettingCurve.length - 1) {
            await setSegmentOverallPrg(key, schedule.progress + 1, now.add(Duration(seconds: ebbinghausForgettingCurve.last)));
          } else {
            await setSegmentOverallPrg(key, schedule.progress + 1, now.add(Duration(seconds: ebbinghausForgettingCurve[schedule.progress + 1])));
          }
        }
      }
    } else {
      await setScheduleCurrentWithCache(segmentTodayPrg, learnOrReview, segmentTodayPrg.progress + 1, now);
    }
  }

  @transaction
  Future<List<String>> tryClear() async {
    await forUpdate();
    var ret = await findAllSegmentCurrentPrg();
    var count = 0;
    for (var r in ret) {
      if (r.progress == maxRepeatTime) {
        count++;
      }
    }
    if (count == ret.length) {
      await deleteSegmentCurrentPrg();
    }
    return ret.map((e) => e.key).toList();
  }

  Future<void> setScheduleCurrentWithCache(SegmentCurrentPrg segmentTodayPrg, bool learnOrReview, int progress, DateTime now) async {
    var key = segmentTodayPrg.key;
    await setSegmentCurrentPrg(key, learnOrReview, progress, now);
    segmentTodayPrg.progress = progress;
    segmentTodayPrg.viewTime = now;
  }
}
