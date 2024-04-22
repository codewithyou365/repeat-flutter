// dao/schedule_dao.dart

import 'dart:math';

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/num.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
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

  static int intervalSeconds = ebbinghausForgettingCurve[1];
  static int findLearnCountPerDay = 45;
  static int learnCountPerDay = 4;
  static int learnCountPerGroup = 2;
  static const int maxLearnCountPerGroup = 1000;
  static int maxRepeatTime = 3;

  //static List<int> review = [3 * 24 * 60 * 60, 7 * 24 * 60 * 60];
  static List<int> review = [0, 30];
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

  @Query('SELECT count(1) FROM SegmentCurrentPrg')
  Future<int?> totalSegmentCurrentPrg();

  @Query("SELECT `key` FROM SegmentCurrentPrg")
  Future<List<String>> findAllSegmentCurrentPrg();

  @Query("SELECT * FROM SegmentCurrentPrg where learnOrReview=:learnOrReview limit 1")
  Future<SegmentCurrentPrg?> findOneSegmentCurrentPrg(bool learnOrReview);

  @Query('DELETE FROM SegmentCurrentPrg')
  Future<void> deleteSegmentCurrentPrg();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSegmentCurrentPrg(List<SegmentCurrentPrg> entities);

  @Query('SELECT * FROM SegmentCurrentPrg where progress<:maxProgress order by viewTime,sort asc')
  Future<List<SegmentCurrentPrg>> findSegmentCurrentPrg(int maxProgress);

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
      " WHERE SegmentReview.createDate=:now")
  Future<List<SegmentReview>> findReviewed(Date now);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertSegmentTodayReview(List<SegmentTodayReview> review);

  @Query("SELECT ifnull(min(createDate),0) FROM SegmentReview"
      " JOIN Segment ON Segment.`key` = SegmentReview.`key`"
      " WHERE SegmentReview.count=:reviewCount"
      " and SegmentReview.createDate<=:now"
      " order by createDate")
  Future<int?> findReviewedMinCreateDate(int reviewCount, Date now);

  @Query("SELECT Segment.key"
      ",Segment.sort"
      ",SegmentReviewKey.createDate"
      " FROM Segment"
      " JOIN (SELECT `key`,group_concat(createDate) createDate FROM SegmentReview"
      " WHERE SegmentReview.count=:reviewCount"
      " and SegmentReview.createDate>=:minCreateDate"
      " group by SegmentReview.key"
      " limit :limit) SegmentReviewKey on SegmentReviewKey.`key`=Segment.`key`"
      " order by sort")
  Future<List<SegmentReviewContentInDb>> scheduleReviewToday(int reviewCount, int minCreateDate, int limit);

  @Query("SELECT Segment.key"
      ",Segment.sort"
      ",'0' createDate"
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
  Future<List<SegmentCurrentPrg>> initToday(Map<String, String>? forReview) async {
    await forUpdate();
    var now = DateTime.now();
    var learnOrReview = true;
    if (forReview != null) {
      learnOrReview = false;
    }
    List<SegmentCurrentPrg> tps = <SegmentCurrentPrg>[];
    {
      var needToDelete = false;
      var needToInsert = false;
      var tp = await findOneSegmentCurrentPrg(learnOrReview);
      if (tp == null) {
        needToInsert = true;
      } else if (tp.createTime.compareTo(now.subtract(Duration(seconds: intervalSeconds))) < 0) {
        needToDelete = true;
        needToInsert = true;
      }

      if (needToDelete) {
        await deleteSegmentCurrentPrg();
        await deleteSegmentTodayReview();
      }

      if (needToInsert) {
        List<SegmentReviewContentInDb> tss = [];
        if (learnOrReview) {
          tss = await forLearnInsert(now);
        } else {
          tss = await forReviewInsert(now, forReview!);
        }
        if (tss.isEmpty) {
          return [];
        }
        for (var ts in tss) {
          tps.add(SegmentCurrentPrg(ts.key, learnOrReview, ts.sort, 0, DateTime.fromMicrosecondsSinceEpoch(0), DateTime.now()));
        }
        await insertSegmentCurrentPrg(tps);
      } else {
        tps = await findSegmentCurrentPrg(maxRepeatTime);
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

  Future<List<SegmentReviewContentInDb>> forReviewInsert(DateTime now, Map<String, String> keyToCreateDate) async {
    for (int i = 0; i < review.length; i++) {
      var minCreateDate = await findReviewedMinCreateDate(i, Date.from(now.subtract(Duration(seconds: review[i]))));
      if (minCreateDate == null) {
        continue;
      }
      List<SegmentReview> reviewed = await findReviewed(Date.from(now));
      if (reviewMaxCount - reviewed.length <= 0) {
        continue;
      }
      List<SegmentReviewContentInDb> tss = await scheduleReviewToday(i, minCreateDate, reviewMaxCount - reviewed.length);
      for (var value in tss) {
        keyToCreateDate[value.key] = value.createDate;
      }
      return tss;
    }
    return [];
  }

  @transaction
  Future<void> error(SegmentCurrentPrg scheduleCurrent, String createDate) async {
    await forUpdate();
    var learnOrReview = createDate == "";
    var key = scheduleCurrent.key;
    var now = DateTime.now();
    await setSegmentOverallPrg(key, 0, now.add(Duration(seconds: intervalSeconds)));
    await setScheduleCurrentWithCache(scheduleCurrent, learnOrReview, 0, now);
  }

  @transaction
  Future<void> right(SegmentCurrentPrg segmentTodayPrg, String createDate) async {
    await forUpdate();
    var learnOrReview = createDate == "";
    var key = segmentTodayPrg.key;
    var now = DateTime.now();
    bool complete = false;
    if (segmentTodayPrg.progress == 0 && DateTime.fromMicrosecondsSinceEpoch(0).compareTo(segmentTodayPrg.viewTime) == 0) {
      complete = true;
      await setScheduleCurrentWithCache(segmentTodayPrg, learnOrReview, maxRepeatTime, now);
    }

    if (segmentTodayPrg.progress + 1 > maxRepeatTime) {
      complete = true;
      await setScheduleCurrentWithCache(segmentTodayPrg, learnOrReview, maxRepeatTime, now);
    }
    if (complete) {
      var schedule = await getSegmentOverallPrg(key);
      if (schedule == null) {
        return;
      }
      if (schedule.next.compareTo(now) < 0) {
        if (createDate != "") {
          await insertSegmentTodayReview(SegmentTodayReview.from(Num.toInts(createDate), key));
        } else {
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
  Future<List<String>> finishCurrent() async {
    await forUpdate();
    var ret = await findAllSegmentCurrentPrg();
    await deleteSegmentCurrentPrg();
    await insertSegmentReview(SegmentReview.from(ret));
    return ret;
  }

  Future<void> setScheduleCurrentWithCache(SegmentCurrentPrg segmentTodayPrg, bool learnOrReview, int progress, DateTime now) async {
    var key = segmentTodayPrg.key;
    await setSegmentCurrentPrg(key, learnOrReview, progress, now);
    segmentTodayPrg.progress = progress;
    segmentTodayPrg.viewTime = now;
  }
}
