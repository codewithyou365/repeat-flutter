// dao/schedule_dao.dart

import 'dart:convert' as convert;

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
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/logic/model/segment_overall_prg_with_key.dart';
import 'package:repeat_flutter/logic/model/segment_review_with_key.dart';
import 'package:repeat_flutter/logic/model/segment_today_prg_with_key.dart';

// ebbinghaus learning config
class ElConfig {
  String title;
  bool random;
  bool extend;
  int level;
  int learnCount;
  int learnCountPerGroup;

  ElConfig(this.title, this.random, this.extend, this.level, this.learnCount, this.learnCountPerGroup);

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'random': random,
      'extend': extend,
      'level': level,
      'learnCount': learnCount,
      'learnCountPerGroup': learnCountPerGroup,
    };
  }

  factory ElConfig.fromJson(Map<String, dynamic> json) {
    return ElConfig(
      json['title'],
      json['random'],
      json['extend'],
      json['level'],
      json['learnCount'],
      json['learnCountPerGroup'],
    );
  }

  tr() {
    var key = "labelElConfig";
    List<String> args = [level.toString()];
    key += random ? "1" : "0";
    key += extend ? "1" : "0";
    key += learnCount > 0 ? "1" : "0";
    if (learnCount > 0) args.add(learnCount.toString());
    key += learnCountPerGroup > 0 ? "1" : "0";
    if (learnCountPerGroup > 0) args.add(learnCountPerGroup.toString());
    I18nKey ret = I18nKey.values.firstWhere(
      (e) => e.name == key,
      orElse: () => throw ArgumentError('Invalid I18nKey: $key'),
    );
    return ret.trArgs(args);
  }

  trWithTitle() {
    var desc = tr();
    if (title != "") {
      desc = "$title:$desc";
    }
    return desc;
  }
}

// review ebbinghaus learning config
class RelConfig {
  String title;
  int level;
  int before;
  Date from;
  int learnCountPerGroup;

  RelConfig(this.title, this.level, this.before, this.from, this.learnCountPerGroup);

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'level': level,
      'before': before,
      'chase': level,
      'from': from.value,
      'learnCountPerGroup': learnCountPerGroup,
    };
  }

  factory RelConfig.fromJson(Map<String, dynamic> json) {
    return RelConfig(
      json['title'],
      json['level'],
      json['before'],
      Date(json['from']),
      json['learnCountPerGroup'],
    );
  }

  tr() {
    var key = "labelRelConfig";
    List<String> args = [level.toString(), before.toString(), from.value.toString()];
    key += learnCountPerGroup > 0 ? "1" : "0";
    if (learnCountPerGroup > 0) args.add(learnCountPerGroup.toString());
    I18nKey ret = I18nKey.values.firstWhere(
      (e) => e.name == key,
      orElse: () => throw ArgumentError('Invalid I18nKey: $key'),
    );
    return ret.trArgs(args);
  }

  trWithTitle() {
    var desc = tr();
    if (title != "") {
      desc = "$title:$desc";
    }
    return desc;
  }
}

class ScheduleConfig {
  List<int> forgettingCurve;
  int intervalSeconds;
  int maxRepeatTime;
  List<ElConfig> elConfigs;
  List<RelConfig> relConfigs;

  ScheduleConfig(
    this.forgettingCurve,
    this.intervalSeconds,
    this.maxRepeatTime,
    this.elConfigs,
    this.relConfigs,
  );

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> elConfigsJson = elConfigs.map((elConfig) => elConfig.toJson()).toList();
    List<Map<String, dynamic>> relConfigsJson = relConfigs.map((relConfig) => relConfig.toJson()).toList();

    return {
      'forgettingCurve': forgettingCurve,
      'intervalSeconds': intervalSeconds,
      'maxRepeatTime': maxRepeatTime,
      'elConfigs': elConfigsJson,
      'relConfigs': relConfigsJson,
    };
  }

  factory ScheduleConfig.fromJson(Map<String, dynamic> json) {
    var elConfigsList = json['elConfigs'] as List;
    var relConfigsList = json['relConfigs'] as List;

    return ScheduleConfig(
      (json['forgettingCurve'] as List).map((e) => e as int).toList(),
      json['intervalSeconds'] as int,
      json['maxRepeatTime'] as int,
      elConfigsList.map((e) => ElConfig.fromJson(e as Map<String, dynamic>)).toList(),
      relConfigsList.map((e) => RelConfig.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

@dao
abstract class ScheduleDao {
  static ScheduleConfig scheduleConfig = ScheduleConfig([], 0, 0, [], []);

  static ScheduleConfig defaultScheduleConfig = ScheduleConfig(
    [
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
    ],
    12 * 60 * 60,
    3,
    [
      ElConfig(/* title */ "", /* random */ false, /* extendLevel */ false, /* level */ 0, /* learnCount */ 2, /* learnCountPerGroup */ 2),
      ElConfig(/* title */ "", /* random */ false, /* extendLevel */ false, /* level */ 1, /* learnCount */ 2, /* learnCountPerGroup */ 2),
      ElConfig(/* title */ "", /* random  */ true, /* extendLevel  */ true, /* level */ 1, /* learnCount */ 2, /* learnCountPerGroup */ 2),
    ],
    [
      RelConfig(/* title */ "", /* level */ 0, /* before */ 3, /* from */ Date(20240321), /* learnCountPerGroup */ 0),
      RelConfig(/* title */ "", /* level */ 1, /* before */ 7, /* from */ Date(20240321), /* learnCountPerGroup */ 0),
    ],
  );

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
  Future<int?> intKv(String crn, CrK k);

  @Query("SELECT value FROM CrKv WHERE crn=:crn and k=:k")
  Future<String?> stringKv(String crn, CrK k);

  @Query('UPDATE CrKv SET value=:value WHERE crn=:crn and k=:k')
  Future<void> updateKv(String crn, CrK k, String value);

  @Query('DELETE FROM SegmentTodayPrg where segmentKeyId in (:ids)')
  Future<void> deleteSegmentTodayPrgByIds(List<int> ids);

  @Query('DELETE FROM SegmentTodayPrg where segmentKeyId in (:ids) and reviewCreateDate!=0')
  Future<void> deleteSegmentTodayReviewPrgByIds(List<int> ids);

  @Query('DELETE FROM SegmentTodayPrg where segmentKeyId in (:ids) and reviewCreateDate=0')
  Future<void> deleteSegmentTodayLearnPrgByIds(List<int> ids);

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
  Future<List<SegmentTodayPrgWithKey>> scheduleLearn(String crn, int minProgress, Date now);

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
      " ORDER BY SegmentOverallPrg.segmentKeyId asc")
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

  @Query("SELECT LimitSegment.segmentKeyId"
      " FROM (SELECT Segment.sort,Segment.segmentKeyId"
      "  FROM Segment"
      "  JOIN SegmentKey ON SegmentKey.id = Segment.segmentKeyId AND SegmentKey.crn=:crn"
      "  WHERE Segment.sort<(SELECT Segment.sort FROM Segment WHERE Segment.segmentKeyId=:segmentKeyId)"
      "  ORDER BY Segment.sort desc"
      "  LIMIT :offset) LimitSegment"
      "  ORDER BY LimitSegment.sort"
      " LIMIT 1")
  Future<int?> getPrevSegmentKeyIdWithOffset(String crn, int segmentKeyId, int offset);

  @Query("SELECT LimitSegment.segmentKeyId"
      " FROM (SELECT Segment.sort,Segment.segmentKeyId"
      "  FROM Segment"
      "  JOIN SegmentKey ON SegmentKey.id = Segment.segmentKeyId AND SegmentKey.crn=:crn"
      "  WHERE Segment.sort>(SELECT Segment.sort FROM Segment WHERE Segment.segmentKeyId=:segmentKeyId)"
      "  ORDER BY Segment.sort"
      "  LIMIT :offset) LimitSegment"
      "  ORDER BY LimitSegment.sort desc"
      " LIMIT 1")
  Future<int?> getNextSegmentKeyIdWithOffset(String crn, int segmentKeyId, int offset);

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

  @Query('DELETE FROM Segment WHERE segmentKeyId=:segmentKeyId')
  Future<void> deleteSegment(int segmentKeyId);

  @Query('DELETE FROM SegmentKey WHERE id=:segmentKeyId')
  Future<void> deleteSegmentKey(int segmentKeyId);

  @Query('DELETE FROM SegmentOverallPrg WHERE segmentKeyId=:segmentKeyId')
  Future<void> deleteSegmentOverallPrg(int segmentKeyId);

  @Query('DELETE FROM SegmentReview WHERE segmentKeyId=:segmentKeyId')
  Future<void> deleteSegmentReview(int segmentKeyId);

  @Query('DELETE FROM SegmentTodayPrg WHERE segmentKeyId=:segmentKeyId')
  Future<void> deleteSegmentTodayPrg(int segmentKeyId);

  @transaction
  Future<void> deleteBySegmentKeyId(int segmentKeyId) async {
    await forUpdate();
    await deleteSegment(segmentKeyId);
    await deleteSegmentKey(segmentKeyId);
    await deleteSegmentOverallPrg(segmentKeyId);
    await deleteSegmentReview(segmentKeyId);
    await deleteSegmentTodayPrg(segmentKeyId);
  }

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
    var todayLearnCreateDate = await intKv(Classroom.curr, CrK.todayLearnCreateDate);
    if (todayLearnCreateDate == null) {
      needToInsert = true;
    }
    if (todayLearnCreateDate != null && Date.from(now).value != todayLearnCreateDate) {
      needToInsert = true;
    }

    scheduleConfig = await getScheduleConfig();

    if (needToInsert) {
      await insertKv(CrKv(Classroom.curr, CrK.todayLearnCreateDate, "${Date.from(now).value}"));
      var ids = await getSegmentKeyIdByCrn(Classroom.curr);
      await deleteSegmentTodayPrgByIds(ids);
      var elConfigs = scheduleConfig.elConfigs;
      await initTodayEl(now, elConfigs, todayPrg);
      var relConfigs = scheduleConfig.relConfigs;
      await initTodayRel(now, relConfigs, todayPrg);
      await insertSegmentTodayPrg(todayPrg);
      var configInUseStr = convert.json.encode(scheduleConfig);
      await insertKv(CrKv(Classroom.curr, CrK.todayLearnScheduleConfigInUse, configInUseStr));
    } else {
      todayPrg = await findSegmentTodayPrg(Classroom.curr);
    }
    return todayPrg;
  }

  @transaction
  Future<List<SegmentTodayPrgWithKey>> forceInitToday(TodayPrgType type) async {
    scheduleConfig = await getScheduleConfig();
    var ids = await getSegmentKeyIdByCrn(Classroom.curr);
    List<SegmentTodayPrgWithKey> todayPrg = [];
    var now = DateTime.now();
    if (type == TodayPrgType.learn || type == TodayPrgType.none) {
      await deleteSegmentTodayLearnPrgByIds(ids);
      var elConfigs = scheduleConfig.elConfigs;
      await initTodayEl(now, elConfigs, todayPrg);
    }
    if (type == TodayPrgType.review || type == TodayPrgType.none) {
      await deleteSegmentTodayReviewPrgByIds(ids);
      var relConfigs = scheduleConfig.relConfigs;
      await initTodayRel(now, relConfigs, todayPrg);
    }
    await insertSegmentTodayPrg(todayPrg);

    var configInUseStr = convert.json.encode(scheduleConfig);
    await insertKv(CrKv(Classroom.curr, CrK.todayLearnScheduleConfigInUse, configInUseStr));

    return await findSegmentTodayPrg(Classroom.curr);
  }

  Future<ScheduleConfig> getScheduleConfig() async {
    // init config
    var configJsonStr = await stringKv(Classroom.curr, CrK.todayLearnScheduleConfig);
    if (configJsonStr == null) {
      configJsonStr = convert.json.encode(defaultScheduleConfig);
      await insertKv(CrKv(Classroom.curr, CrK.todayLearnScheduleConfig, configJsonStr));
    }
    Map<String, dynamic> configJson = convert.jsonDecode(configJsonStr);
    return ScheduleConfig.fromJson(configJson);
  }

  Future<void> initTodayEl(DateTime now, List<ElConfig> elConfigs, List<SegmentTodayPrgWithKey> todayPrg) async {
    if (elConfigs.isNotEmpty) {
      int minLevel = (1 << 63) - 1;
      for (var config in elConfigs) {
        if (config.level < minLevel) {
          minLevel = config.level;
        }
      }
      var all = await scheduleLearn(Classroom.curr, minLevel, Date.from(now));
      for (int i = 0; i < elConfigs.length; ++i) {
        var config = elConfigs[i];
        if (!config.random) {
          todayPrg.addAll(refineEl(all, i, config));
        }
      }
      all.shuffle();
      for (int i = 0; i < elConfigs.length; ++i) {
        var config = elConfigs[i];
        if (config.random) {
          todayPrg.addAll(refineEl(all, i, config));
        }
      }
    }
  }

  Future<void> initTodayRel(DateTime now, List<RelConfig> relConfigs, List<SegmentTodayPrgWithKey> todayPrg) async {
    for (int index = relConfigs.length - 1; index >= 0; --index) {
      var relConfig = relConfigs[index];
      if (index != relConfig.level) {
        continue;
      }
      if (relConfig.before < 0) {
        continue;
      }
      if (relConfig.learnCountPerGroup < 0) {
        continue;
      }
      if (Date.from(now).value < relConfig.from.value) {
        continue;
      }
      var shouldStartDate = Date.from(now.subtract(Duration(days: relConfig.before)));
      if (shouldStartDate.value < relConfig.from.value) {
        continue;
      }
      var startDateInt = await findReviewedMinCreateDate(Classroom.curr, index, shouldStartDate);
      if (startDateInt == null || startDateInt == -1) {
        continue;
      }
      if (startDateInt < relConfig.from.value) {
        startDateInt = relConfig.from.value;
      }
      List<SegmentTodayPrgWithKey> sls = await scheduleReview(Classroom.curr, relConfig.level, Date(startDateInt));
      SegmentTodayPrg.setType(sls, TodayPrgType.review, index, relConfig.learnCountPerGroup);
      todayPrg.addAll(sls);
    }
  }

  List<SegmentTodayPrgWithKey> refineEl(List<SegmentTodayPrgWithKey> all, int index, ElConfig config) {
    List<SegmentTodayPrgWithKey> curr;
    if (config.extend) {
      curr = all.where((sl) {
        return sl.progress >= config.level;
      }).toList();
    } else {
      curr = all.where((sl) {
        return sl.progress == config.level;
      }).toList();
    }
    if (curr.isEmpty) {
      return curr;
    }
    List<SegmentTodayPrgWithKey> ret;
    if (config.learnCount <= 0) {
      ret = curr;
    } else {
      ret = curr.sublist(0, curr.length < config.learnCount ? curr.length : config.learnCount);
    }
    all.removeWhere((a) => ret.any((b) => a.k == b.k));

    for (int i = 0; i < ret.length; i++) {
      ret[i].progress = 0;
    }
    SegmentTodayPrg.setType(ret, TodayPrgType.learn, index, config.learnCountPerGroup);
    return ret;
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
  Future<void> right(SegmentTodayPrg segmentTodayPrg, int? progress) async {
    await forUpdate();
    var segmentKeyId = segmentTodayPrg.segmentKeyId;
    var now = DateTime.now();
    bool complete = false;
    var maxRepeatTime = scheduleConfig.maxRepeatTime;
    if (progress != null && progress > 0) {
      complete = true;
      await setPrg4Sop(segmentKeyId, progress - 1);
      await setScheduleCurrentWithCache(segmentTodayPrg, maxRepeatTime, now);
    }
    if (complete == false && segmentTodayPrg.progress == 0 && DateTime.fromMicrosecondsSinceEpoch(0).compareTo(segmentTodayPrg.viewTime) == 0) {
      complete = true;
      await setScheduleCurrentWithCache(segmentTodayPrg, maxRepeatTime, now);
    }

    if (complete == false && segmentTodayPrg.progress + 1 >= maxRepeatTime) {
      complete = true;
      await setScheduleCurrentWithCache(segmentTodayPrg, maxRepeatTime, now);
    }
    if (complete) {
      var schedule = await getSegmentOverallPrg(segmentKeyId);
      if (schedule == null) {
        return;
      }
      var adjustProgress = false;
      if (segmentTodayPrg.reviewCreateDate.value != 0) {
        await setSegmentReviewCount(segmentTodayPrg.reviewCreateDate, segmentKeyId, segmentTodayPrg.reviewCount + 1);
        if (schedule.progress == 0) {
          adjustProgress = true;
        }
      } else {
        var todayLearnCreateDate = await intKv(Classroom.curr, CrK.todayLearnCreateDate);
        todayLearnCreateDate ??= Date.from(now).value;
        await insertSegmentReview([SegmentReview(Date(todayLearnCreateDate), segmentKeyId, 0)]);
        adjustProgress = true;
      }
      if (adjustProgress) {
        var forgettingCurve = scheduleConfig.forgettingCurve;
        if (schedule.progress + 1 >= forgettingCurve.length - 1) {
          await setPrgAndNext4Sop(segmentKeyId, schedule.progress + 1, getNext(now, forgettingCurve.last));
        } else {
          await setPrgAndNext4Sop(segmentKeyId, schedule.progress + 1, getNext(now, forgettingCurve[schedule.progress + 1]));
        }
      }
    } else {
      await setScheduleCurrentWithCache(segmentTodayPrg, segmentTodayPrg.progress + 1, now);
    }
  }

  Future<void> setScheduleCurrentWithCache(SegmentTodayPrg segmentTodayPrg, int progress, DateTime now) async {
    var finish = false;
    if (progress >= scheduleConfig.maxRepeatTime) {
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
