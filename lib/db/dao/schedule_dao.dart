// dao/schedule_dao.dart

import 'dart:convert';

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
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
  static int learnCountPerGroup = 2;
  static int maxRepeatTime = 3;

  static List<int> learn = [2, 4];
  static List<int> review = [3 * 24 * 60 * 60, 7 * 24 * 60 * 60];

  //static List<int> review = [0, 30];

  static int catchUpAdditionDay = 1;

  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  @delete
  Future<void> deleteContentIndex(ContentIndex data);

  @delete
  Future<void> deleteSegments(List<Segment> data);

  /// --- SegmentTodayPrg ---

  @Query('SELECT count(1) FROM SegmentTodayPrg where crn=:crn and learnOrReview=:learnOrReview')
  Future<int?> totalSegmentTodayPrg(String crn, bool learnOrReview);

  @Query("SELECT * FROM SegmentTodayPrg where crn=:crn and learnOrReview=:learnOrReview")
  Future<List<SegmentTodayPrg>> findAllSegmentTodayPrg(String crn, bool learnOrReview);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertKv(CrKv kv);

  @delete
  Future<void> deleteKv(CrKv kv);

  @Query("SELECT CAST(value as INTEGER) FROM CrKv WHERE crn=:crn and `k`=:k")
  Future<int?> value(String crn, CrK k);

  @Query("SELECT * FROM SegmentTodayPrg where crn=:crn limit 1")
  Future<SegmentTodayPrg?> findOneSegmentTodayPrg(String crn);

  @Query('DELETE FROM SegmentTodayPrg where crn=:crn')
  Future<void> deleteSegmentTodayPrg(String crn);

  @Query('DELETE FROM SegmentTodayPrg where crn=:crn')
  Future<void> deleteAllSegmentTodayPrg(String crn);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertSegmentTodayPrg(List<SegmentTodayPrg> entities);

  @Query('SELECT * FROM SegmentTodayPrg where crn=:crn order by id asc')
  Future<List<SegmentTodayPrg>> findSegmentTodayPrg(String crn);

  @Query('UPDATE SegmentTodayPrg SET progress=:progress,viewTime=:viewTime,finish=:finish WHERE crn=:crn and `k`=:k and type=:type')
  Future<void> setSegmentTodayPrg(String crn, String k, int type, int progress, DateTime viewTime, bool finish);

  @Query("SELECT count(1) FROM SegmentReview"
      " JOIN SegmentOverallPrg ON SegmentOverallPrg.crn=:crn and SegmentOverallPrg.`k` = SegmentReview.`k`"
      " JOIN Segment ON Segment.crn=:crn and Segment.`k` = SegmentReview.`k`"
      " WHERE SegmentReview.createDate=:now")
  Future<int?> findLearnedCount(String crn, Date now);

  @Query("SELECT ifnull(min(createDate),-1) FROM SegmentReview"
      " JOIN Segment ON Segment.crn=:crn and Segment.`k` = SegmentReview.`k`"
      " WHERE SegmentReview.crn=:crn"
      " and SegmentReview.count=:reviewCount"
      " and SegmentReview.createDate<=:now"
      " order by createDate")
  Future<int?> findReviewedMinCreateDate(String crn, int reviewCount, Date now);

  @Query("SELECT SegmentReview.crn"
      ",SegmentReview.`k`"
      ",0 type"
      ",Segment.sort"
      ",0 progress"
      ",0 viewTime"
      ",SegmentReview.count reviewCount"
      ",SegmentReview.createDate reviewCreateDate"
      ",0 finish"
      " FROM SegmentReview"
      " JOIN Segment ON Segment.crn=:crn"
      "  AND Segment.`k`=SegmentReview.`k`"
      " WHERE SegmentReview.crn=:crn"
      " AND SegmentReview.count=:reviewCount"
      " AND SegmentReview.createDate>=:startDate"
      " AND SegmentReview.createDate<=:endDate"
      " ORDER BY Segment.sort")
  Future<List<SegmentTodayPrg>> scheduleReview(String crn, int reviewCount, Date startDate, Date endDate);

  @Query("SELECT * FROM ("
      " SELECT Segment.crn"
      ",Segment.k"
      ",0 type"
      ",Segment.sort"
      ",0 progress"
      ",0 viewTime"
      ",0 reviewCount"
      ",0 reviewCreateDate"
      ",0 finish"
      " FROM SegmentOverallPrg"
      " JOIN Segment ON Segment.crn=:crn"
      "  and Segment.`k` = SegmentOverallPrg.`k`"
      " where SegmentOverallPrg.crn=:crn"
      " and SegmentOverallPrg.next<=:now"
      " and SegmentOverallPrg.progress=:progress"
      " order by SegmentOverallPrg.progress,Segment.sort limit :limit"
      " ) Segment order by Segment.sort")
  Future<List<SegmentTodayPrg>> scheduleLearn1(String crn, int progress, int limit, Date now);

  @Query("SELECT * FROM ("
      " SELECT Segment.crn"
      ",Segment.k"
      ",0 type"
      ",Segment.sort"
      ",0 progress"
      ",0 viewTime"
      ",0 reviewCount"
      ",0 reviewCreateDate"
      ",0 finish"
      " FROM SegmentOverallPrg"
      " JOIN Segment ON Segment.crn=:crn"
      "  and Segment.`k` = SegmentOverallPrg.`k`"
      " where SegmentOverallPrg.crn=:crn"
      " and SegmentOverallPrg.next<=:now"
      " and SegmentOverallPrg.progress>=:minProgress"
      " order by SegmentOverallPrg.progress,Segment.sort limit :limit"
      " ) Segment order by Segment.sort")
  Future<List<SegmentTodayPrg>> scheduleLearn2(String crn, int minProgress, int limit, Date now);

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

  @Query('UPDATE SegmentReview SET count=:count WHERE crn=:crn and createDate=:createDate and `k`=:k')
  Future<void> setSegmentReviewCount(String crn, Date createDate, String k, int count);

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
  Future<List<SegmentTodayPrg>> initToday() async {
    await forUpdate();
    List<SegmentTodayPrg> todayPrg = [];
    var now = DateTime.now();
    var needToInsert = false;
    var todayLearnCreateDate = await value(Classroom.curr, CrK.todayLearnCreateDate);
    if (todayLearnCreateDate == null) {
      needToInsert = true;
    }
    if (todayLearnCreateDate != null && Date.from(now).value != todayLearnCreateDate) {
      needToInsert = true;
    }

    if (needToInsert) {
      await insertKv(CrKv(Classroom.curr, CrK.todayLearnCreateDate, "${Date.from(now).value}"));
      var config = json.encode({"learn": learn, "review": review});
      await insertKv(CrKv(Classroom.curr, CrK.todayLearnScheduleConfig, config));
      await deleteAllSegmentTodayPrg(Classroom.curr);

      var lastLevel = learn.length - 1;
      // learn 0
      for (int i = 0; i < lastLevel; ++i) {
        var sls = await scheduleLearn1(Classroom.curr, i, learn[i], Date.from(now));
        SegmentTodayPrg.setType(sls, TodayPrgType.learn, i, learnCountPerGroup);
        todayPrg.addAll(sls);
      }
      // learn 1,...
      {
        var sls = await scheduleLearn2(Classroom.curr, lastLevel, learn[lastLevel], Date.from(now));
        SegmentTodayPrg.setType(sls, TodayPrgType.learn, lastLevel, learnCountPerGroup);
        todayPrg.addAll(sls);
      }

      // review ...,1,0
      for (int i = review.length - 1; i >= 0; --i) {
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
        List<SegmentTodayPrg> sls = await scheduleReview(Classroom.curr, i, startDate, endDate);
        SegmentTodayPrg.setType(sls, TodayPrgType.review, i, 0);
        todayPrg.addAll(sls);
      }
      await insertSegmentTodayPrg(todayPrg);
    } else {
      todayPrg = await findSegmentTodayPrg(Classroom.curr);
    }
    return todayPrg;
  }

  @transaction
  Future<void> error(SegmentTodayPrg scheduleCurrent) async {
    await forUpdate();
    var k = scheduleCurrent.k;
    var now = DateTime.now();
    await setPrg4Sop(Classroom.curr, k, 0);
    await setScheduleCurrentWithCache(scheduleCurrent, 0, now);
  }

  @transaction
  Future<void> right(SegmentTodayPrg segmentTodayPrg) async {
    await forUpdate();
    var k = segmentTodayPrg.k;
    var now = DateTime.now();
    bool complete = false;
    if (segmentTodayPrg.progress == 0 && DateTime.fromMicrosecondsSinceEpoch(0).compareTo(segmentTodayPrg.viewTime) == 0) {
      complete = true;
      await setScheduleCurrentWithCache(segmentTodayPrg, maxRepeatTime, now);
    }

    if (segmentTodayPrg.progress + 1 >= maxRepeatTime) {
      complete = true;
      await setScheduleCurrentWithCache(segmentTodayPrg, maxRepeatTime, now);
    }
    if (complete) {
      if (segmentTodayPrg.reviewCreateDate.value != 0) {
        await setSegmentReviewCount(Classroom.curr, segmentTodayPrg.reviewCreateDate, k, segmentTodayPrg.reviewCount + 1);
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
      await setScheduleCurrentWithCache(segmentTodayPrg, segmentTodayPrg.progress + 1, now);
    }
  }

  Future<void> setScheduleCurrentWithCache(SegmentTodayPrg segmentTodayPrg, int progress, DateTime now) async {
    var finish = false;
    if (progress >= maxRepeatTime) {
      finish = true;
    }
    await setSegmentTodayPrg(
      Classroom.curr,
      segmentTodayPrg.k,
      segmentTodayPrg.type,
      progress,
      now,
      finish,
    );
    segmentTodayPrg.progress = progress;
    segmentTodayPrg.viewTime = now;
    segmentTodayPrg.finish = finish;
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
