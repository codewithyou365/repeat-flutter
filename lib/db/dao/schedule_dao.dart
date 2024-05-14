// dao/schedule_dao.dart

import 'dart:math';

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/num.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
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

  //static List<int> review = [0, 30];

  static int catchUpAdditionDay = 1;

  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  @delete
  Future<void> deleteContentIndex(ContentIndex data);

  @delete
  Future<void> deleteSegments(List<Segment> data);

  /// --- SegmentCurrentPrg ---

  @Query('SELECT count(1) FROM SegmentCurrentPrg where crn=:crn and learnOrReview=:learnOrReview')
  Future<int?> totalSegmentCurrentPrg(String crn, bool learnOrReview);

  @Query("SELECT * FROM SegmentCurrentPrg where crn=:crn and learnOrReview=:learnOrReview")
  Future<List<SegmentCurrentPrg>> findAllSegmentCurrentPrg(String crn, bool learnOrReview);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertKv(CrKv kv);

  @delete
  Future<void> deleteKv(CrKv kv);

  @Query("SELECT CAST(value as INTEGER) FROM CrKv WHERE crn=:crn and `k`=:k")
  Future<int?> value(String crn, CrK k);

  @Query("SELECT * FROM SegmentCurrentPrg where crn=:crn and learnOrReview=:learnOrReview limit 1")
  Future<SegmentCurrentPrg?> findOneSegmentCurrentPrg(String crn, bool learnOrReview);

  @Query('DELETE FROM SegmentCurrentPrg where crn=:crn and learnOrReview=:learnOrReview')
  Future<void> deleteSegmentCurrentPrg(String crn, bool learnOrReview);

  @Query('DELETE FROM SegmentCurrentPrg where crn=:crn')
  Future<void> deleteAllSegmentCurrentPrg(String crn);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertSegmentCurrentPrg(List<SegmentCurrentPrg> entities);

  @Query('SELECT * FROM SegmentCurrentPrg where crn=:crn and learnOrReview=:learnOrReview and progress<:maxProgress order by viewTime,sort asc')
  Future<List<SegmentCurrentPrg>> findSegmentCurrentPrg(String crn, bool learnOrReview, int maxProgress);

  @Query('UPDATE SegmentCurrentPrg SET progress=:progress,viewTime=:viewTime WHERE crn=:crn and `k`=:k and learnOrReview=:learnOrReview')
  Future<void> setSegmentCurrentPrg(String crn, String k, bool learnOrReview, int progress, DateTime viewTime);

  @Query("SELECT count(1) FROM SegmentReview"
      " JOIN SegmentOverallPrg ON SegmentOverallPrg.crn=:crn and SegmentOverallPrg.`k` = SegmentReview.`k`"
      " JOIN Segment ON Segment.crn=:crn and Segment.`k` = SegmentReview.`k`"
      " WHERE SegmentReview.createDate=:now")
  Future<int?> findLearnedCount(String crn, Date now);

  @Query("SELECT SegmentOverallPrg.* FROM SegmentReview"
      " JOIN SegmentOverallPrg ON SegmentOverallPrg.crn=:crn and SegmentOverallPrg.`k` = SegmentReview.`k`"
      " JOIN Segment ON Segment.crn=:crn and Segment.`k` = SegmentReview.`k`"
      " WHERE SegmentReview.crn=:crn and SegmentReview.createDate=:now")
  Future<List<SegmentOverallPrg>> findLearned(String crn, Date now);

  @Query('DELETE FROM SegmentTodayReview where crn=:crn')
  Future<void> deleteSegmentTodayReview(String crn);

  @Query("SELECT SegmentReview.k FROM SegmentTodayReview"
      " JOIN SegmentReview ON SegmentReview.crn=:crn"
      "  AND SegmentReview.createDate = SegmentTodayReview.createDate"
      "  ANd SegmentReview.`k` = SegmentTodayReview.`k`"
      " JOIN Segment ON Segment.crn=:crn and Segment.`k` = SegmentReview.`k`"
      " WHERE SegmentTodayReview.crn=:crn and SegmentTodayReview.createDate=:now"
      " AND SegmentTodayReview.finish=true"
      " AND SegmentTodayReview.count=:count")
  Future<List<String>> todayFinishReviewed(String crn, Date now, int count);

  @Query("SELECT * FROM SegmentTodayReview WHERE SegmentTodayReview.crn=:crn and SegmentTodayReview.finish=false limit 1")
  Future<SegmentTodayReview?> findTodayReviewUnfinished(String crn);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertSegmentTodayReview(List<SegmentTodayReview> review);

  @Query('UPDATE SegmentTodayReview SET finish=1 WHERE crn=:crn createDate in (:createDate) and `k`=:k')
  Future<void> setSegmentTodayReviewFinish(String crn, List<Date> createDate, String k);

  @Query("SELECT ifnull(min(createDate),-1) FROM SegmentReview"
      " JOIN Segment ON Segment.crn=:crn and Segment.`k` = SegmentReview.`k`"
      " WHERE SegmentReview.crn=:crn"
      " and SegmentReview.count=:reviewCount"
      " and SegmentReview.createDate<=:now"
      " order by createDate")
  Future<int?> findReviewedMinCreateDate(String crn, int reviewCount, Date now);

  @Query("SELECT Segment.crn"
      ",Segment.k"
      ",Segment.sort"
      ",SegmentReviewKey.createDate reviewCreateDate"
      ",SegmentReviewKey.count reviewCount"
      " FROM Segment"
      " JOIN (SELECT `k`"
      "  ,group_concat(createDate) createDate"
      "  ,min(SegmentReview.count) count"
      "  FROM SegmentReview"
      "  WHERE SegmentReview.crn=:crn"
      "  and SegmentReview.count=:reviewCount"
      "  and SegmentReview.createDate>=:startDate"
      "  and SegmentReview.createDate<=:endDate"
      "  group by SegmentReview.k"
      ") SegmentReviewKey on SegmentReviewKey.`k`=Segment.`k`"
      " WHERE Segment.crn=:crn"
      " order by sort")
  Future<List<SegmentReviewContentInDb>> shouldTodayReview(String crn, int reviewCount, Date startDate, Date endDate);

  @Query("SELECT Segment.crn"
      ",Segment.k"
      ",Segment.sort"
      ",'0' reviewCreateDate"
      ",0 reviewCount"
      " FROM SegmentOverallPrg"
      " JOIN Segment ON Segment.crn=:crn"
      "  and Segment.`k` = SegmentOverallPrg.`k`"
      " where Segment.crn=:crn"
      " and SegmentOverallPrg.next<=:now order by SegmentOverallPrg.progress limit :limit")
  Future<List<SegmentReviewContentInDb>> scheduleLearnToday(String crn, int limit, Date now);

  @Query("SELECT count(1) FROM SegmentOverallPrg"
      " JOIN Segment ON Segment.crn=:crn and Segment.`k` = SegmentOverallPrg.`k`"
      " where SegmentOverallPrg.crn=:crn and next<=:now order by progress,sort limit :limit")
  Future<int?> findSegmentOverallPrgCount(String crn, int limit, Date now);

  @Query('UPDATE SegmentOverallPrg SET progress=:progress,next=:next WHERE crn=:crn and `k`=:k')
  Future<void> setPrgAndNext4Sop(String crn, String k, int progress, Date next);

  @Query('UPDATE SegmentOverallPrg SET progress=:progress WHERE crn=:crn and `k`=:k')
  Future<void> setPrg4Sop(String crn, String k, int progress);

  @Query("SELECT * FROM SegmentOverallPrg WHERE crn=:crn and `k`=:k")
  Future<SegmentOverallPrg?> getSegmentOverallPrg(String crn, String k);

  @Query("SELECT * FROM SegmentOverallPrg WHERE crn=:crn order by next desc")
  Future<List<SegmentOverallPrg>> getAllSegmentOverallPrg(String crn);

  /// --- SegmentReview

  @Query("SELECT * FROM SegmentReview WHERE crn=:crn order by createDate desc")
  Future<List<SegmentReview>> getAllSegmentReview(String crn);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertSegmentReview(List<SegmentReview> review);

  @Query('UPDATE SegmentReview SET count=:count WHERE crn=:crn and createDate in (:createDate) and `k`=:k')
  Future<void> setSegmentReviewCount(String crn, List<Date> createDate, String k, int count);

  @Query("SELECT"
      " Segment.crn"
      ",Segment.`k` `k`"
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
      " WHERE Segment.crn=:crn and Segment.`k`=:k")
  Future<SegmentContentInDb?> getSegmentContent(String crn, String k);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSegments(List<Segment> entities);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertSegmentOverallPrgs(List<SegmentOverallPrg> entities);

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
    await deleteContentIndex(ContentIndex(Classroom.curr, url, 0));
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
      var todayLearnCreateDate = await value(Classroom.curr, CrK.todayLearnCreateDate);
      if (todayLearnCreateDate != null && Date.from(now).value != todayLearnCreateDate) {
        needToDelete = true;
        needToInsert = true;
      } else {
        var tp = await findOneSegmentCurrentPrg(Classroom.curr, learnOrReview);
        if (tp == null) {
          needToInsert = true;
        }
      }

      if (needToDelete) {
        await deleteKv(CrKv(Classroom.curr, CrK.todayLearnCreateDate, ""));
        await deleteAllSegmentCurrentPrg(Classroom.curr);
        await deleteSegmentTodayReview(Classroom.curr);
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
          tps.add(SegmentCurrentPrg(Classroom.curr, ts.k, learnOrReview, ts.sort, 0, DateTime.fromMicrosecondsSinceEpoch(0)));
        }
        await insertSegmentCurrentPrg(tps);
      } else {
        if (learnOrReview) {
          tps = await findSegmentCurrentPrg(Classroom.curr, learnOrReview, maxRepeatTime);
        } else {
          tps = await findSegmentCurrentPrg(Classroom.curr, learnOrReview, maxRepeatTime);
          await forReviewInsert(now, forReview!, needInsertToday);
        }
      }
    }
    if (needInsertToday[0]) {
      List<SegmentTodayReview> todayReviews = [];
      if (forReview!.isNotEmpty) {
        forReview.forEach((k, value) {
          todayReviews.addAll(value);
        });
        todayReviews.sort((a, b) {
          if (a.createDate != b.createDate) {
            return a.createDate.value.compareTo(b.createDate.value);
          } else {
            return a.k.compareTo(b.k);
          }
        });
        await insertSegmentTodayReview(todayReviews);
      }
    }
    return tps;
  }

  Future<List<SegmentReviewContentInDb>> forLearnInsert(DateTime now) async {
    List<SegmentOverallPrg> learned = await findLearned(Classroom.curr, Date.from(now));
    if (learned.length >= learnCountPerDay) {
      return [];
    }
    List<SegmentReviewContentInDb> tss = await scheduleLearnToday(Classroom.curr, findLearnCountPerDay, Date.from(now));
    tss.sort((a, b) => a.sort.compareTo(b.sort));
    tss = tss.sublist(0, min(min(learnCountPerGroup, tss.length), learnCountPerDay - learned.length));
    return tss;
  }

  Future<List<SegmentReviewContentInDb>> forReviewInsert(
    DateTime now,
    Map<String, List<SegmentTodayReview>> keyToCreateDate,
    List<bool> needInsertToday,
  ) async {
    int? currReviewLevel;
    SegmentTodayReview? todayReviewUnfinished = await findTodayReviewUnfinished(Classroom.curr);
    if (todayReviewUnfinished == null) {
      needInsertToday[0] = true;
    } else {
      needInsertToday[0] = false;
      currReviewLevel = todayReviewUnfinished.count;
    }
    for (int i = review.length - 1; i >= 0; --i) {
      if (currReviewLevel != null && i != currReviewLevel) {
        continue;
      }

      var shouldStartDate = Date.from(now.subtract(Duration(seconds: review[i])));
      var startDateInt = await findReviewedMinCreateDate(Classroom.curr, i, shouldStartDate);
      if (startDateInt == null || startDateInt == -1) {
        continue;
      }
      var startDate = Date(startDateInt);
      var endDate = startDate;
      if (startDate.value != shouldStartDate.value) {
        // If we need to catch up, we should only pursue it for one day.
        endDate = Date.from(startDate.toDateTime().add(Duration(days: catchUpAdditionDay)));
      }
      List<SegmentReviewContentInDb> all = await shouldTodayReview(Classroom.curr, i, startDate, endDate);

      if (all.isEmpty) {
        continue;
      }
      for (var r in all) {
        var dates = Num.toInts(r.reviewCreateDate);
        List<SegmentTodayReview> value = [];
        for (var date in dates) {
          value.add(SegmentTodayReview(Classroom.curr, Date(date), r.k, r.reviewCount, false));
        }
        keyToCreateDate[r.k] = value;
      }
      List<String> finished = await todayFinishReviewed(Classroom.curr, Date.from(now), i);
      all.removeWhere((segmentReview) => finished.any((k) => k == segmentReview.k));
      return all;
    }

    return [];
  }

  @transaction
  Future<void> error(SegmentCurrentPrg scheduleCurrent, List<SegmentTodayReview> reviews) async {
    await forUpdate();
    var learnOrReview = reviews.isEmpty;
    var k = scheduleCurrent.k;
    var now = DateTime.now();
    await insertKv(CrKv(Classroom.curr, CrK.todayLearnCreateDate, "${Date.from(now).value}"));
    await setPrg4Sop(Classroom.curr, k, 0);
    await setScheduleCurrentWithCache(scheduleCurrent, learnOrReview, 0, now);
  }

  @transaction
  Future<void> right(SegmentCurrentPrg segmentTodayPrg, List<SegmentTodayReview> reviews) async {
    await forUpdate();
    var learnOrReview = reviews.isEmpty;
    var k = segmentTodayPrg.k;
    var now = DateTime.now();
    await insertKv(CrKv(Classroom.curr, CrK.todayLearnCreateDate, "${Date.from(now).value}"));
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
        await setSegmentReviewCount(Classroom.curr, createDates, k, reviews.first.count + 1);
        await setSegmentTodayReviewFinish(Classroom.curr, createDates, k);
      } else {
        var schedule = await getSegmentOverallPrg(Classroom.curr, k);
        if (schedule == null) {
          return;
        }
        await insertSegmentReview([SegmentReview(Classroom.curr, Date.from(now), k, 0)]);
        if (schedule.next.value <= Date.from(now).value) {
          if (schedule.progress + 1 >= ebbinghausForgettingCurve.length - 1) {
            await setPrgAndNext4Sop(Classroom.curr, k, schedule.progress + 1, getNext(now, ebbinghausForgettingCurve.last));
          } else {
            await setPrgAndNext4Sop(Classroom.curr, k, schedule.progress + 1, getNext(now, ebbinghausForgettingCurve[schedule.progress + 1]));
          }
        }
      }
    } else {
      await setScheduleCurrentWithCache(segmentTodayPrg, learnOrReview, segmentTodayPrg.progress + 1, now);
    }
  }

  @transaction
  Future<List<String>> tryClear(bool learnOrReview) async {
    await forUpdate();
    var ret = await findAllSegmentCurrentPrg(Classroom.curr, learnOrReview);
    var count = 0;
    for (var r in ret) {
      if (r.progress == maxRepeatTime) {
        count++;
      }
    }
    if (count == ret.length) {
      await deleteSegmentCurrentPrg(Classroom.curr, learnOrReview);
    }
    return ret.map((e) => e.k).toList();
  }

  Future<void> setScheduleCurrentWithCache(SegmentCurrentPrg segmentTodayPrg, bool learnOrReview, int progress, DateTime now) async {
    var k = segmentTodayPrg.k;
    await setSegmentCurrentPrg(Classroom.curr, k, learnOrReview, progress, now);
    segmentTodayPrg.progress = progress;
    segmentTodayPrg.viewTime = now;
  }

  Date getNext(DateTime now, int seconds) {
    var a = Date.from(now);
    var b = Date.from(now.add(Duration(seconds: seconds)));
    if (a.value == b.value) {
      return Date.from(now.add(const Duration(days: 1)));
    } else {
      return b;
    }
  }
}
