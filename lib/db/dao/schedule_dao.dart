// dao/schedule_dao.dart

import 'dart:convert';

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/segment.dart';
import 'package:repeat_flutter/db/entity/segment_key.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';
import 'package:repeat_flutter/db/entity/segment_review.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/logic/model/segment_overall_prg_with_key.dart';
import 'package:repeat_flutter/logic/model/segment_review_with_key.dart';
import 'package:repeat_flutter/logic/model/segment_today_prg_with_key.dart';

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

  static List<int> learn = [2, 2];
  static Map<int, int> levelToResidueLearn = {1: 2};
  static List<int> review = [3 * 24 * 60 * 60, 7 * 24 * 60 * 60];

  //static List<int> review = [0, 30];

  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  @delete
  Future<void> deleteContentIndex(ContentIndex data);

  @Query('SELECT SegmentKey.id FROM SegmentKey'
      ' JOIN Segment ON Segment.segmentKeyId=SegmentKey.id'
      '  AND Segment.indexDocId=:indexDocId'
      ' WHERE SegmentKey.crn=:crn')
  Future<List<int>> getSegmentKeyId(String crn, int indexDocId);

  @Query('SELECT SegmentKey.id FROM SegmentKey'
      ' WHERE SegmentKey.crn=:crn')
  Future<List<int>> getSegmentKeyIdByCrn(String crn);

  @delete
  Future<void> deleteSegments(List<Segment> data);

  /// --- SegmentTodayPrg ---

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertKv(CrKv kv);

  @delete
  Future<void> deleteKv(CrKv kv);

  @Query("SELECT CAST(value as INTEGER) FROM CrKv WHERE crn=:crn and k=:k")
  Future<int?> valueKv(String crn, CrK k);

  @Query('DELETE FROM SegmentTodayPrg where segmentKeyId in (:ids)')
  Future<void> deleteSegmentTodayPrgByIds(List<int> ids);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertSegmentTodayPrg(List<SegmentTodayPrg> entities);

  @Query('SELECT SegmentTodayPrg.*'
      ',SegmentKey.k'
      ' FROM SegmentTodayPrg'
      " JOIN SegmentKey on SegmentKey.id=SegmentTodayPrg.segmentKeyId"
      " AND SegmentKey.crn=:crn"
      ' order by id asc')
  Future<List<SegmentTodayPrgWithKey>> findSegmentTodayPrg(String crn);

  @Query('UPDATE SegmentTodayPrg SET progress=:progress,viewTime=:viewTime,finish=:finish WHERE segmentKeyId=:segmentKeyId and type=:type')
  Future<void> setSegmentTodayPrg(int segmentKeyId, int type, int progress, DateTime viewTime, bool finish);

  @Query("SELECT ifnull(min(SegmentReview.createDate),-1) FROM SegmentReview"
      " JOIN Segment ON Segment.segmentKeyId=SegmentReview.segmentKeyId"
      " JOIN SegmentKey on SegmentKey.id=SegmentReview.segmentKeyId"
      " AND SegmentKey.crn=:crn"
      " WHERE SegmentReview.count=:reviewCount"
      " and SegmentReview.createDate<=:now"
      " order by createDate")
  Future<int?> findReviewedMinCreateDate(String crn, int reviewCount, Date now);

  @Query("SELECT SegmentReview.segmentKeyId"
      ",0 type"
      ",Segment.sort"
      ",0 progress"
      ",0 viewTime"
      ",SegmentReview.count reviewCount"
      ",SegmentReview.createDate reviewCreateDate"
      ",0 finish"
      ",SegmentKey.k"
      " FROM SegmentReview"
      " JOIN SegmentKey on SegmentKey.id=SegmentReview.segmentKeyId AND SegmentKey.crn=:crn"
      " JOIN Segment ON Segment.segmentKeyId=SegmentReview.segmentKeyId"
      " WHERE SegmentReview.count=:reviewCount"
      " AND SegmentReview.createDate=:startDate"
      " ORDER BY Segment.sort")
  Future<List<SegmentTodayPrgWithKey>> scheduleReview(String crn, int reviewCount, Date startDate);

  @Query("SELECT * FROM ("
      " SELECT SegmentOverallPrg.segmentKeyId"
      ",0 type"
      ",Segment.sort"
      ",0 progress"
      ",0 viewTime"
      ",0 reviewCount"
      ",0 reviewCreateDate"
      ",0 finish"
      ",SegmentKey.k"
      " FROM SegmentOverallPrg"
      " JOIN SegmentKey on SegmentKey.id=SegmentOverallPrg.segmentKeyId AND SegmentKey.crn=:crn"
      " JOIN Segment ON Segment.segmentKeyId=SegmentOverallPrg.segmentKeyId"
      " where SegmentOverallPrg.next<=:now"
      " and SegmentOverallPrg.progress=:progress"
      " order by SegmentOverallPrg.progress,Segment.sort limit :limit"
      " ) Segment order by Segment.sort")
  Future<List<SegmentTodayPrgWithKey>> scheduleLearn1(String crn, int progress, int limit, Date now);

  @Query("SELECT * FROM ("
      " SELECT SegmentOverallPrg.segmentKeyId"
      ",0 type"
      ",Segment.sort"
      ",SegmentOverallPrg.progress progress"
      ",0 viewTime"
      ",0 reviewCount"
      ",0 reviewCreateDate"
      ",0 finish"
      ",SegmentKey.k"
      " FROM SegmentOverallPrg"
      " JOIN SegmentKey on SegmentKey.id=SegmentOverallPrg.segmentKeyId AND SegmentKey.crn=:crn"
      " JOIN Segment ON Segment.segmentKeyId=SegmentOverallPrg.segmentKeyId"
      " where SegmentOverallPrg.next<=:now"
      " and SegmentOverallPrg.progress>=:minProgress"
      " order by SegmentOverallPrg.progress,Segment.sort"
      " ) Segment order by Segment.sort")
  Future<List<SegmentTodayPrgWithKey>> scheduleLearn2(String crn, int minProgress, Date now);

  @Query('UPDATE SegmentOverallPrg SET progress=:progress,next=:next WHERE segmentKeyId=:segmentKeyId')
  Future<void> setPrgAndNext4Sop(int segmentKeyId, int progress, Date next);

  @Query('UPDATE SegmentOverallPrg SET progress=:progress WHERE segmentKeyId=:segmentKeyId')
  Future<void> setPrg4Sop(int segmentKeyId, int progress);

  @Query("SELECT * FROM SegmentOverallPrg WHERE segmentKeyId=:segmentKeyId")
  Future<SegmentOverallPrg?> getSegmentOverallPrg(int segmentKeyId);

  @Query("SELECT SegmentOverallPrg.*"
      ",SegmentKey.crn"
      ",SegmentKey.k"
      " FROM SegmentOverallPrg"
      " JOIN SegmentKey on SegmentKey.id=SegmentOverallPrg.segmentKeyId"
      " AND SegmentKey.crn=:crn"
      " ORDER BY next desc, segmentKeyId asc")
  Future<List<SegmentOverallPrgWithKey>> getAllSegmentOverallPrg(String crn);

  /// --- SegmentReview

  @Query("SELECT SegmentReview.*"
      ",SegmentKey.crn"
      ",SegmentKey.k"
      " FROM SegmentReview"
      " JOIN SegmentKey on SegmentKey.id=SegmentReview.segmentKeyId"
      " AND SegmentKey.crn=:crn"
      " ORDER BY createDate desc, segmentKeyId asc")
  Future<List<SegmentReviewWithKey>> getAllSegmentReview(String crn);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertSegmentReview(List<SegmentReview> review);

  @Query('UPDATE SegmentReview SET count=:count WHERE createDate=:createDate and `segmentKeyId`=:segmentKeyId')
  Future<void> setSegmentReviewCount(Date createDate, int segmentKeyId, int count);

  @Query("SELECT"
      " Segment.segmentKeyId"
      ",IFNULL(indexDoc.id,0) indexDocId"
      ",IFNULL(mediaDoc.id,0) mediaDocId"
      ",Segment.lessonIndex lessonIndex"
      ",Segment.segmentIndex segmentIndex"
      ",Segment.sort sort"
      ",SegmentKey.crn crn"
      ",SegmentKey.k k"
      ",IFNULL(indexDoc.url,'') indexDocUrl"
      ",IFNULL(indexDoc.path,'') indexDocPath"
      ",IFNULL(mediaDoc.path,'') mediaDocPath"
      " FROM Segment"
      " JOIN SegmentKey segmentKey ON segmentKey.id=:segmentKeyId"
      " LEFT JOIN Doc indexDoc ON indexDoc.id=Segment.indexDocId"
      " LEFT JOIN Doc mediaDoc ON mediaDoc.id=Segment.mediaDocId"
      " WHERE Segment.segmentKeyId=:segmentKeyId")
  Future<SegmentContentInDb?> getSegmentContent(int segmentKeyId);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertSegmentKeys(List<SegmentKey> entities);

  @Query('SELECT SegmentKey.* FROM SegmentKey'
      ' WHERE SegmentKey.crn=:crn'
      ' and SegmentKey.k in (:keys)')
  Future<List<SegmentKey>> getSegmentKey(String crn, List<String> keys);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSegments(List<Segment> entities);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertSegmentOverallPrgs(List<SegmentOverallPrg> entities);

  /// for manager
  @transaction
  Future<void> importSegment(
    List<SegmentKey> rawSegmentKeys,
    List<Segment> segments,
    List<SegmentOverallPrg> segmentOverallPrgs,
  ) async {
    await forUpdate();
    for (var segmentKey in rawSegmentKeys) {
      if (segmentKey.crn != Classroom.curr) {
        return;
      }
    }

    await insertSegmentKeys(rawSegmentKeys);
    List<String> keys = rawSegmentKeys.map((segmentKey) => segmentKey.k).toList();
    List<SegmentKey> segmentKeys = await getSegmentKey(Classroom.curr, keys);
    Map<String, SegmentKey> keyToSegmentKey = {};
    for (var segmentKey in segmentKeys) {
      keyToSegmentKey[segmentKey.k] = segmentKey;
    }
    for (var i = 0; i < rawSegmentKeys.length; i++) {
      var rawSegmentKey = rawSegmentKeys[i];
      var segmentKeyWithId = keyToSegmentKey[rawSegmentKey.k];
      var id = segmentKeyWithId!.id!;
      segments[i].segmentKeyId = id;
      segmentOverallPrgs[i].segmentKeyId = id;
    }
    await insertSegments(segments);
    await insertSegmentOverallPrgs(segmentOverallPrgs);
  }

  @transaction
  Future<void> deleteContent(String url, int indexDocId) async {
    await forUpdate();
    await deleteContentIndex(ContentIndex(Classroom.curr, url, 0));
    List<Segment> delSegments = [];
    var ids = await getSegmentKeyId(Classroom.curr, indexDocId);
    for (var id in ids) {
      delSegments.add(Segment(id, 0, 0, 0, 0, 0));
    }
    await deleteSegments(delSegments);
  }

  /// for progress
  @transaction
  Future<List<SegmentTodayPrgWithKey>> initToday() async {
    await forUpdate();
    List<SegmentTodayPrgWithKey> todayPrg = [];
    var now = DateTime.now();
    var needToInsert = false;
    var todayLearnCreateDate = await valueKv(Classroom.curr, CrK.todayLearnCreateDate);
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
      var ids = await getSegmentKeyIdByCrn(Classroom.curr);
      await deleteSegmentTodayPrgByIds(ids);

      // learn 0
      for (int i = 0; i < learn.length; ++i) {
        var sls = await scheduleLearn1(Classroom.curr, i, learn[i], Date.from(now));
        SegmentTodayPrg.setType(sls, TodayPrgType.learn, i, learnCountPerGroup);
        todayPrg.addAll(sls);
      }
      // learn 1,...
      if (levelToResidueLearn.isNotEmpty) {
        int minLevel = (1 << 63) - 1;
        for (var level in levelToResidueLearn.keys) {
          if (level < minLevel) {
            minLevel = level;
          }
        }
        var sls = await scheduleLearn2(Classroom.curr, minLevel, Date.from(now));
        sls.shuffle();
        for (var level in levelToResidueLearn.keys) {
          var currLevelSls = sls.where((sl) {
            return sl.progress >= level;
          }).toList();

          var limit = levelToResidueLearn[level];
          currLevelSls = currLevelSls.sublist(0, limit);
          sls.removeWhere((sl) => currLevelSls.any((currSl) => sl.k == currSl.k));

          for (int i = 0; i < currLevelSls.length; i++) {
            currLevelSls[i].progress = 0;
          }
          SegmentTodayPrg.setType(currLevelSls, TodayPrgType.learn, level, learnCountPerGroup);
          todayPrg.addAll(currLevelSls);
        }
      }

      // review ...,1,0
      List<Date> reviewDays = [];
      List<int> reviewLevel = [];
      for (int i = review.length - 1; i >= 0; --i) {
        var shouldStartDate = Date.from(now.subtract(Duration(seconds: review[i])));
        var startDateInt = await findReviewedMinCreateDate(Classroom.curr, i, shouldStartDate);
        if (startDateInt == null || startDateInt == -1) {
          continue;
        }
        var startDate = Date(startDateInt);
        reviewDays.add(startDate);
        reviewLevel.add(i);
        if (startDate.value != shouldStartDate.value) {
          // If we need to catch up, we should only pursue it for one day.
          reviewDays.add(Date.from(startDate.toDateTime().add(const Duration(days: 1))));
          reviewLevel.add(i);
        }
      }
      for (int i = 0; i < reviewDays.length; ++i) {
        var reviewDay = reviewDays[i];
        List<SegmentTodayPrgWithKey> sls = await scheduleReview(Classroom.curr, reviewLevel[i], reviewDay);
        SegmentTodayPrg.setType(sls, TodayPrgType.review, i, 0);
        todayPrg.addAll(sls);
      }
      await insertSegmentTodayPrg(todayPrg);
    } else {
      todayPrg = await findSegmentTodayPrg(Classroom.curr);
    }
    todayPrg.sort((a, b) => a.sort.compareTo(b.sort));
    return todayPrg;
  }

  @transaction
  Future<void> error(SegmentTodayPrg scheduleCurrent) async {
    await forUpdate();
    var segmentKeyId = scheduleCurrent.segmentKeyId;
    var now = DateTime.now();
    await setPrg4Sop(segmentKeyId, 0);
    await setScheduleCurrentWithCache(scheduleCurrent, 0, now);
  }

  @transaction
  Future<void> right(SegmentTodayPrg segmentTodayPrg) async {
    await forUpdate();
    var segmentKeyId = segmentTodayPrg.segmentKeyId;
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
        await setSegmentReviewCount(segmentTodayPrg.reviewCreateDate, segmentKeyId, segmentTodayPrg.reviewCount + 1);
      } else {
        var schedule = await getSegmentOverallPrg(segmentKeyId);
        if (schedule == null) {
          return;
        }
        await insertSegmentReview([SegmentReview(Date.from(now), segmentKeyId, 0)]);
        if (schedule.next.value <= Date.from(now).value) {
          if (schedule.progress + 1 >= ebbinghausForgettingCurve.length - 1) {
            await setPrgAndNext4Sop(segmentKeyId, schedule.progress + 1, getNext(now, ebbinghausForgettingCurve.last));
          } else {
            await setPrgAndNext4Sop(segmentKeyId, schedule.progress + 1, getNext(now, ebbinghausForgettingCurve[schedule.progress + 1]));
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
      segmentTodayPrg.segmentKeyId,
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
