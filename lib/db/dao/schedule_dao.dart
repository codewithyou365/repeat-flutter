// dao/schedule_dao.dart

import 'dart:convert' as convert;

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
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
import 'package:repeat_flutter/db/entity/segment_stats.dart';

// ebbinghaus learning config
class ElConfig {
  String title;
  bool random;
  int level;
  int toLevel;
  int learnCount;
  int learnCountPerGroup;

  ElConfig(this.title, this.random, this.level, this.toLevel, this.learnCount, this.learnCountPerGroup);

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'random': random,
      'level': level,
      'toLevel': toLevel,
      'learnCount': learnCount,
      'learnCountPerGroup': learnCountPerGroup,
    };
  }

  factory ElConfig.fromJson(Map<String, dynamic> json) {
    return ElConfig(
      json['title'],
      json['random'],
      json['level'],
      json['toLevel'] ?? 0,
      json['learnCount'],
      json['learnCountPerGroup'],
    );
  }

  tr() {
    var key = "labelElConfig";
    List<String> args = [level.toString()];
    key += random ? "1" : "0";
    key += level != toLevel ? "1" : "0";
    if (level != toLevel) args.add(toLevel.toString());
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
      // LW: listen and write.
      // LR: listen and recall.
      // TR: tip and recall.
      // TW: tip and write.
      ElConfig(/* title */ "LW1", /* random */ false, /* level */ 0, /* toLevel */ 0, /* learnCount */ 10, /* learnCountPerGroup  */ 0),
      ElConfig(/* title */ "LR2", /* random */ false, /* level */ 1, /* toLevel */ 5, /* learnCount */ 90, /* learnCountPerGroup  */ 0),
    ],
    [],
  );

  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  @Query('UPDATE Content set hide=true,docId=0'
      ' WHERE Content.id=:id')
  Future<void> hideContent(int id);

  /// --- SegmentTodayPrg ---

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertKv(CrKv kv);

  @delete
  Future<void> deleteKv(CrKv kv);

  @Query("SELECT CAST(value as INTEGER) FROM CrKv WHERE classroomId=:classroomId and k=:k")
  Future<int?> intKv(int classroomId, CrK k);

  @Query("SELECT value FROM CrKv WHERE classroomId=:classroomId and k=:k")
  Future<String?> stringKv(int classroomId, CrK k);

  @Query('UPDATE CrKv SET value=:value WHERE classroomId=:classroomId and k=:k')
  Future<void> updateKv(int classroomId, CrK k, String value);

  @Query('DELETE FROM SegmentTodayPrg WHERE classroomId=:classroomId')
  Future<void> deleteSegmentTodayPrgByClassroomId(int classroomId);

  @Query('DELETE FROM SegmentTodayPrg where classroomId=:classroomId and reviewCreateDate>100')
  Future<void> deleteSegmentTodayReviewPrgByClassroomId(int classroomId);

  @Query('DELETE FROM SegmentTodayPrg where classroomId=:classroomId and reviewCreateDate=0')
  Future<void> deleteSegmentTodayLearnPrgByClassroomId(int classroomId);

  @Query('DELETE FROM SegmentTodayPrg where classroomId=:classroomId and reviewCreateDate=1')
  Future<void> deleteSegmentTodayFullCustomPrgByClassroomId(int classroomId);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertSegmentTodayPrg(List<SegmentTodayPrg> entities);

  @Query('SELECT *'
      ' FROM SegmentTodayPrg'
      " WHERE classroomId=:classroomId"
      ' order by id asc')
  Future<List<SegmentTodayPrg>> findSegmentTodayPrg(int classroomId);

  @Query('UPDATE SegmentTodayPrg SET progress=:progress,viewTime=:viewTime,finish=:finish WHERE segmentKeyId=:segmentKeyId and type=:type')
  Future<void> setSegmentTodayPrg(int segmentKeyId, int type, int progress, DateTime viewTime, bool finish);

  @Query("SELECT count(Segment.segmentKeyId) FROM Segment"
      " AND Segment.classroomId=:classroomId"
      " WHERE Segment.contentSerial=:contentSerial"
      " and Segment.lessonIndex=:lessonIndex")
  Future<int?> lessonCount(int classroomId, int contentSerial, int lessonIndex);

  @Query("SELECT IFNULL(MIN(SegmentReview.createDate),-1) FROM SegmentReview"
      " JOIN Segment ON Segment.segmentKeyId=SegmentReview.segmentKeyId"
      " WHERE SegmentReview.classroomId=:classroomId"
      " AND SegmentReview.count=:reviewCount"
      " and SegmentReview.createDate<=:now"
      " order by SegmentReview.createDate")
  Future<int?> findReviewedMinCreateDate(int classroomId, int reviewCount, Date now);

  @Query("SELECT"
      " SegmentReview.classroomId"
      ",Segment.contentSerial"
      ",SegmentReview.segmentKeyId"
      ",0 time"
      ",0 type"
      ",Segment.sort"
      ",0 progress"
      ",0 viewTime"
      ",SegmentReview.count reviewCount"
      ",SegmentReview.createDate reviewCreateDate"
      ",0 finish"
      " FROM SegmentReview"
      " JOIN Segment ON Segment.segmentKeyId=SegmentReview.segmentKeyId"
      " WHERE SegmentReview.classroomId=:classroomId"
      " AND SegmentReview.count=:reviewCount"
      " AND SegmentReview.createDate=:startDate"
      " ORDER BY Segment.sort")
  Future<List<SegmentTodayPrg>> scheduleReview(int classroomId, int reviewCount, Date startDate);

  @Query("SELECT * FROM ("
      " SELECT"
      " Segment.classroomId"
      ",Segment.contentSerial"
      ",SegmentOverallPrg.segmentKeyId"
      ",0 time"
      ",0 type"
      ",Segment.sort"
      ",SegmentOverallPrg.progress progress"
      ",0 viewTime"
      ",0 reviewCount"
      ",0 reviewCreateDate"
      ",0 finish"
      " FROM SegmentOverallPrg"
      " JOIN Segment ON Segment.segmentKeyId=SegmentOverallPrg.segmentKeyId AND Segment.classroomId=:classroomId"
      " WHERE SegmentOverallPrg.next<=:now"
      " AND SegmentOverallPrg.progress>=:minProgress"
      " ORDER BY SegmentOverallPrg.progress,Segment.sort"
      " ) Segment order by Segment.sort")
  Future<List<SegmentTodayPrg>> scheduleLearn(int classroomId, int minProgress, Date now);

  @Query("SELECT"
      " Segment.classroomId"
      ",Segment.contentSerial"
      ",Segment.segmentKeyId"
      ",0 time"
      ",0 type"
      ",Segment.sort"
      ",0 progress"
      ",0 viewTime"
      ",0 reviewCount"
      ",1 reviewCreateDate"
      ",0 finish"
      " FROM Segment"
      " WHERE Segment.classroomId=:classroomId"
      " AND Segment.sort>=("
      "  SELECT Segment.sort FROM Segment"
      "  WHERE Segment.contentSerial=:contentSerial"
      "  AND Segment.lessonIndex=:lessonIndex"
      "  AND Segment.segmentIndex=:segmentIndex"
      ")"
      " ORDER BY Segment.sort"
      " limit :limit"
      "")
  Future<List<SegmentTodayPrg>> scheduleFullCustom(int classroomId, int contentSerial, int lessonIndex, int segmentIndex, int limit);

  @Query('UPDATE SegmentOverallPrg SET progress=:progress,next=:next WHERE segmentKeyId=:segmentKeyId')
  Future<void> setPrgAndNext4Sop(int segmentKeyId, int progress, Date next);

  @Query('UPDATE SegmentOverallPrg SET progress=:progress WHERE segmentKeyId=:segmentKeyId')
  Future<void> setPrg4Sop(int segmentKeyId, int progress);

  @Query("SELECT * FROM SegmentOverallPrg WHERE segmentKeyId=:segmentKeyId")
  Future<SegmentOverallPrg?> getSegmentOverallPrg(int segmentKeyId);

  @Query("SELECT SegmentOverallPrg.*"
      ",Content.name contentName"
      ",Segment.lessonIndex"
      ",Segment.segmentIndex"
      " FROM Segment"
      " JOIN SegmentOverallPrg on SegmentOverallPrg.segmentKeyId=Segment.segmentKeyId"
      " JOIN Content ON Content.classroomId=Segment.classroomId AND Content.serial=Segment.contentSerial"
      " WHERE Segment.classroomId=:classroomId"
      " ORDER BY Segment.sort asc")
  Future<List<SegmentOverallPrgWithKey>> getAllSegmentOverallPrg(int classroomId);

  /// --- SegmentReview
  @Query("SELECT Content.name FROM Content WHERE Content.classroomId=:classroomId AND Content.serial=:contentSerial")
  Future<String?> getContentNameBySerial(int classroomId, int contentSerial);

  @Query("SELECT SegmentReview.*"
      ",Content.name contentName"
      ",Segment.lessonIndex"
      ",Segment.segmentIndex"
      " FROM SegmentReview"
      " JOIN Segment ON Segment.segmentKeyId=SegmentReview.segmentKeyId"
      " JOIN Content ON Content.classroomId=SegmentReview.classroomId AND Content.serial=SegmentReview.contentSerial"
      " WHERE SegmentReview.classroomId=:classroomId"
      " AND SegmentReview.createDate>=:start AND SegmentReview.createDate<=:end"
      " ORDER BY SegmentReview.createDate desc,Segment.sort asc")
  Future<List<SegmentReviewWithKey>> getAllSegmentReview(int classroomId, Date start, Date end);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertSegmentReview(List<SegmentReview> review);

  @Query('UPDATE SegmentReview SET count=:count WHERE createDate=:createDate and `segmentKeyId`=:segmentKeyId')
  Future<void> setSegmentReviewCount(Date createDate, int segmentKeyId, int count);

  @Query("SELECT"
      " Segment.segmentKeyId"
      ",Segment.classroomId"
      ",Segment.contentSerial"
      ",Segment.lessonIndex"
      ",Segment.segmentIndex"
      ",Segment.sort sort"
      ",Content.name contentName"
      " FROM Segment"
      " JOIN Content ON Content.classroomId=Segment.classroomId AND Content.serial=Segment.contentSerial"
      " WHERE Segment.segmentKeyId=:segmentKeyId")
  Future<SegmentContentInDb?> getSegmentContent(int segmentKeyId);

  @Query("SELECT"
      " Content.name contentName"
      " FROM SegmentKey"
      " JOIN Content ON Content.classroomId=SegmentKey.classroomId AND Content.serial=SegmentKey.contentSerial"
      " WHERE SegmentKey.id=:segmentKeyId")
  Future<String?> getContentName(int segmentKeyId);

  @Query("SELECT LimitSegment.segmentKeyId"
      " FROM (SELECT sort,segmentKeyId"
      "  FROM Segment"
      "  WHERE classroomId=:classroomId"
      "  AND sort<(SELECT Segment.sort FROM Segment WHERE Segment.segmentKeyId=:segmentKeyId)"
      "  ORDER BY sort desc"
      "  LIMIT :offset) LimitSegment"
      "  ORDER BY LimitSegment.sort"
      " LIMIT 1")
  Future<int?> getPrevSegmentKeyIdWithOffset(int classroomId, int segmentKeyId, int offset);

  @Query("SELECT LimitSegment.segmentKeyId"
      " FROM (SELECT sort,segmentKeyId"
      "  FROM Segment"
      "  WHERE classroomId=:classroomId"
      "  AND sort>(SELECT Segment.sort FROM Segment WHERE Segment.segmentKeyId=:segmentKeyId)"
      "  ORDER BY sort"
      "  LIMIT :offset) LimitSegment"
      "  ORDER BY LimitSegment.sort desc"
      " LIMIT 1")
  Future<int?> getNextSegmentKeyIdWithOffset(int classroomId, int segmentKeyId, int offset);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertSegmentKeys(List<SegmentKey> entities);

  @Query('SELECT SegmentKey.* FROM SegmentKey'
      ' WHERE SegmentKey.classroomId=:classroomId'
      ' and SegmentKey.contentSerial=:contentSerial')
  Future<List<SegmentKey>> getSegmentKey(int classroomId, int contentSerial);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSegments(List<Segment> entities);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertSegmentOverallPrgs(List<SegmentOverallPrg> entities);

  @Query('DELETE FROM Segment'
      ' WHERE Segment.classroomId=:classroomId'
      ' and Segment.contentSerial=:contentSerial')
  Future<void> deleteSegmentByContentSerial(int classroomId, int contentSerial);

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

  @Query('DELETE FROM Segment WHERE classroomId=:classroomId')
  Future<void> deleteSegmentByClassroomId(int classroomId);

  @Query('DELETE FROM SegmentKey WHERE classroomId=:classroomId')
  Future<void> deleteSegmentKeyByClassroomId(int classroomId);

  @Query('DELETE FROM SegmentOverallPrg WHERE classroomId=:classroomId')
  Future<void> deleteSegmentOverallPrgByClassroomId(int classroomId);

  @Query('DELETE FROM SegmentReview WHERE classroomId=:classroomId')
  Future<void> deleteSegmentReviewByClassroomId(int classroomId);

  @Query('SELECT ifnull(max(Segment.lessonIndex),0) FROM Segment'
      ' WHERE Segment.classroomId=:classroomId'
      ' AND Segment.contentSerial=:contentSerial')
  Future<int?> getMaxLessonIndex(int classroomId, int contentSerial);

  @Query('SELECT ifnull(max(Segment.segmentIndex),0) FROM Segment'
      ' WHERE Segment.classroomId=:classroomId'
      ' AND Segment.contentSerial=:contentSerial'
      ' AND Segment.lessonIndex=:lessonIndex')
  Future<int?> getMaxSegmentIndex(int classroomId, int contentSerial, int lessonIndex);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSegmentStats(SegmentStats stats);

  @transaction
  Future<void> deleteBySegmentKeyId(int segmentKeyId) async {
    await forUpdate();
    await deleteSegment(segmentKeyId);
    await deleteSegmentKey(segmentKeyId);
    await deleteSegmentOverallPrg(segmentKeyId);
    await deleteSegmentReview(segmentKeyId);
    await deleteSegmentTodayPrg(segmentKeyId);
  }

  @transaction
  Future<void> deleteByClassroomId(int classroomId) async {
    await forUpdate();
    await deleteSegmentByClassroomId(classroomId);
    await deleteSegmentKeyByClassroomId(classroomId);
    await deleteSegmentOverallPrgByClassroomId(classroomId);
    await deleteSegmentReviewByClassroomId(classroomId);
    await deleteSegmentTodayPrgByClassroomId(classroomId);
  }

  /// for manager
  @transaction
  Future<void> importSegment(
    List<SegmentKey> rawSegmentKeys,
    List<Segment> segments,
    List<SegmentOverallPrg> segmentOverallPrgs,
  ) async {
    await forUpdate();
    int contentSerial = 0;
    for (var segmentKey in rawSegmentKeys) {
      if (segmentKey.classroomId != Classroom.curr) {
        return;
      }
      contentSerial = segmentKey.contentSerial;
    }
    // The segmentKey data cant be delete
    List<SegmentKey> segmentKeys = await getSegmentKey(Classroom.curr, contentSerial);
    Map<String, SegmentKey> keyToSegmentKey = {};
    for (var segmentKey in segmentKeys) {
      keyToSegmentKey[segmentKey.toStringKey()] = segmentKey;
    }

    List<SegmentKey> needToInsert = [];
    for (var segmentKey in rawSegmentKeys) {
      if (!keyToSegmentKey.containsKey(segmentKey.toStringKey())) {
        needToInsert.add(segmentKey);
      }
    }
    if (needToInsert.isNotEmpty) {
      await insertSegmentKeys(needToInsert);
      segmentKeys = await getSegmentKey(Classroom.curr, contentSerial);
      keyToSegmentKey = {};
      for (var segmentKey in segmentKeys) {
        keyToSegmentKey[segmentKey.toStringKey()] = segmentKey;
      }
    }
    await deleteSegmentByContentSerial(Classroom.curr, contentSerial);
    for (var i = 0; i < rawSegmentKeys.length; i++) {
      var rawSegmentKey = rawSegmentKeys[i];
      var segmentKeyWithId = keyToSegmentKey[rawSegmentKey.toStringKey()];
      var id = segmentKeyWithId!.id!;
      segments[i].segmentKeyId = id;
      segmentOverallPrgs[i].segmentKeyId = id;
    }
    await insertSegments(segments);
    await insertSegmentOverallPrgs(segmentOverallPrgs);
  }

  @transaction
  Future<void> hideContentAndDeleteSegment(int contentId, int contentSerial) async {
    await forUpdate();
    await hideContent(contentId);
    await deleteSegmentByContentSerial(Classroom.curr, contentSerial);
  }

  /// for progress
  @transaction
  Future<List<SegmentTodayPrg>> initToday() async {
    await forUpdate();
    List<SegmentTodayPrg> todayPrg = [];
    var now = DateTime.now();
    var needToInsert = false;
    var todayLearnCreateDate = await intKv(Classroom.curr, CrK.todayScheduleCreateDate);
    if (todayLearnCreateDate == null) {
      needToInsert = true;
    }
    if (todayLearnCreateDate != null && Date.from(now).value != todayLearnCreateDate) {
      needToInsert = true;
    }

    scheduleConfig = await getScheduleConfig();

    if (needToInsert) {
      await deleteKv(CrKv(Classroom.curr, CrK.todayFullCustomScheduleConfigCount, ""));
      await insertKv(CrKv(Classroom.curr, CrK.todayScheduleCreateDate, "${Date.from(now).value}"));
      await deleteSegmentTodayPrgByClassroomId(Classroom.curr);
      var elConfigs = scheduleConfig.elConfigs;
      await initTodayEl(now, elConfigs, todayPrg);
      var relConfigs = scheduleConfig.relConfigs;
      await initTodayRel(now, relConfigs, todayPrg);
      await insertSegmentTodayPrg(todayPrg);
      var configInUseStr = convert.json.encode(scheduleConfig);
      await insertKv(CrKv(Classroom.curr, CrK.todayScheduleConfigInUse, configInUseStr));
    }
    todayPrg = await findSegmentTodayPrg(Classroom.curr);
    return todayPrg;
  }

  @transaction
  Future<List<SegmentTodayPrg>> forceInitToday(TodayPrgType type) async {
    scheduleConfig = await getScheduleConfigByKey(CrK.todayScheduleConfig);
    var scheduleConfigInUse = await getScheduleConfigByKey(CrK.todayScheduleConfigInUse);
    List<SegmentTodayPrg> todayPrg = [];
    var now = DateTime.now();
    if (type == TodayPrgType.learn || type == TodayPrgType.none) {
      await deleteSegmentTodayLearnPrgByClassroomId(Classroom.curr);
      var elConfigs = scheduleConfig.elConfigs;
      scheduleConfigInUse.elConfigs = elConfigs;
      await initTodayEl(now, elConfigs, todayPrg);
    }
    if (type == TodayPrgType.review || type == TodayPrgType.none) {
      await deleteSegmentTodayReviewPrgByClassroomId(Classroom.curr);
      var relConfigs = scheduleConfig.relConfigs;
      scheduleConfigInUse.relConfigs = relConfigs;
      await initTodayRel(now, relConfigs, todayPrg);
    }
    if (type == TodayPrgType.fullCustom || type == TodayPrgType.none) {
      await deleteKv(CrKv(Classroom.curr, CrK.todayFullCustomScheduleConfigCount, ""));
      await deleteSegmentTodayFullCustomPrgByClassroomId(Classroom.curr);
    }
    if (todayPrg.isNotEmpty) {
      await insertSegmentTodayPrg(todayPrg);
    }
    var configInUseStr = convert.json.encode(scheduleConfigInUse);
    await insertKv(CrKv(Classroom.curr, CrK.todayScheduleConfigInUse, configInUseStr));

    return await findSegmentTodayPrg(Classroom.curr);
  }

  Future<ScheduleConfig> getScheduleConfig() async {
    return getScheduleConfigByKey(CrK.todayScheduleConfig);
  }

  Future<ScheduleConfig> getScheduleConfigByKey(CrK config) async {
    var configJsonStr = await stringKv(Classroom.curr, config);
    if (configJsonStr == null) {
      configJsonStr = convert.json.encode(defaultScheduleConfig);
      await insertKv(CrKv(Classroom.curr, config, configJsonStr));
    }
    Map<String, dynamic> configJson = convert.jsonDecode(configJsonStr);
    return ScheduleConfig.fromJson(configJson);
  }

  Future<void> initTodayEl(DateTime now, List<ElConfig> elConfigs, List<SegmentTodayPrg> todayPrg) async {
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

  Future<void> initTodayRel(DateTime now, List<RelConfig> relConfigs, List<SegmentTodayPrg> todayPrg) async {
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
      List<SegmentTodayPrg> sls = await scheduleReview(Classroom.curr, relConfig.level, shouldStartDate);
      if (sls.isEmpty) {
        var startDateInt = await findReviewedMinCreateDate(Classroom.curr, index, shouldStartDate);
        if (startDateInt == null || startDateInt == -1) {
          continue;
        }
        if (startDateInt < relConfig.from.value) {
          startDateInt = relConfig.from.value;
        }
        sls = await scheduleReview(Classroom.curr, relConfig.level, Date(startDateInt));
      }
      SegmentTodayPrg.setType(sls, TodayPrgType.review, index, relConfig.learnCountPerGroup);
      todayPrg.addAll(sls);
    }
  }

  List<SegmentTodayPrg> refineEl(List<SegmentTodayPrg> all, int index, ElConfig config) {
    List<SegmentTodayPrg> curr;
    if (config.level != config.toLevel) {
      curr = all.where((sl) {
        return config.level <= sl.progress && sl.progress <= config.toLevel;
      }).toList();
    } else {
      curr = all.where((sl) {
        return sl.progress == config.level;
      }).toList();
    }
    if (curr.isEmpty) {
      return curr;
    }
    List<SegmentTodayPrg> ret;
    if (config.learnCount <= 0) {
      ret = curr;
    } else {
      ret = curr.sublist(0, curr.length < config.learnCount ? curr.length : config.learnCount);
    }
    all.removeWhere((a) => ret.any((b) => a.segmentKeyId == b.segmentKeyId));

    for (int i = 0; i < ret.length; i++) {
      ret[i].progress = 0;
    }
    SegmentTodayPrg.setType(ret, TodayPrgType.learn, index, config.learnCountPerGroup);
    return ret;
  }

  @transaction
  Future<void> addFullCustom(int contentSerial, int lessonIndex, int segmentIndex, int limit) async {
    List<SegmentTodayPrg> ret;
    ret = await scheduleFullCustom(Classroom.curr, contentSerial, lessonIndex, segmentIndex, limit);
    String? fullCustomJsonStr = await stringKv(Classroom.curr, CrK.todayFullCustomScheduleConfigCount);
    List<List<String>> fullCustomConfigs = ListUtil.toListList(fullCustomJsonStr);
    var contentName = await getContentNameBySerial(Classroom.curr, contentSerial);
    List<String> args = [];
    args.add(contentName ?? '-');
    args.add('${lessonIndex + 1}');
    args.add('${segmentIndex + 1}');
    args.add('$limit');
    fullCustomConfigs.add(args);
    insertKv(CrKv(Classroom.curr, CrK.todayFullCustomScheduleConfigCount, convert.jsonEncode(fullCustomConfigs)));
    SegmentTodayPrg.setType(ret, TodayPrgType.fullCustom, fullCustomConfigs.length - 1, 0);

    await insertSegmentTodayPrg(ret);
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
  Future<void> right(SegmentTodayPrg segmentTodayPrg, int? progress, int? nextDayValue, bool record) async {
    await forUpdate();
    var segmentKeyId = segmentTodayPrg.segmentKeyId;
    bool complete = false;
    int? nextProgress;
    TodayPrgType prgType;
    if (segmentTodayPrg.reviewCreateDate.value == 0) {
      prgType = TodayPrgType.learn;
    } else if (segmentTodayPrg.reviewCreateDate.value == 1) {
      prgType = TodayPrgType.fullCustom;
    } else {
      prgType = TodayPrgType.review;
    }
    var maxRepeatTime = scheduleConfig.maxRepeatTime;
    if (progress != null && progress >= 0 && nextDayValue != null && nextDayValue > 0) {
      complete = true;
      nextProgress = progress;
    } else if (segmentTodayPrg.progress == 0 && DateTime.fromMicrosecondsSinceEpoch(0).compareTo(segmentTodayPrg.viewTime) == 0) {
      complete = true;
      if (prgType == TodayPrgType.learn) {
        var schedule = await getSegmentOverallPrg(segmentKeyId);
        if (schedule == null) {
          return;
        }
        nextProgress = schedule.progress + 1;
      }
    } else if (segmentTodayPrg.progress + 1 >= maxRepeatTime) {
      complete = true;
      nextProgress = 0;
    }

    var now = DateTime.now();
    var todayLearnCreateDate = await intKv(Classroom.curr, CrK.todayScheduleCreateDate);
    todayLearnCreateDate ??= Date.from(now).value;
    if (record) {
      int todayNextProgress;
      if (complete) {
        todayNextProgress = maxRepeatTime;
        switch (prgType) {
          case TodayPrgType.learn:
            await insertSegmentReview([SegmentReview(Date(todayLearnCreateDate), segmentKeyId, Classroom.curr, segmentTodayPrg.contentSerial, 0)]);
            break;
          case TodayPrgType.review:
            await setSegmentReviewCount(segmentTodayPrg.reviewCreateDate, segmentKeyId, segmentTodayPrg.reviewCount + 1);
          default:
            break;
        }
      } else {
        todayNextProgress = segmentTodayPrg.progress + 1;
      }
      await setScheduleCurrentWithCache(segmentTodayPrg, todayNextProgress, now);
      await insertSegmentStats(SegmentStats(segmentKeyId, prgType.index, Date(todayLearnCreateDate), now.millisecondsSinceEpoch, Classroom.curr, segmentTodayPrg.contentSerial));
    }

    if (nextProgress != null) {
      Date nextDay;
      if (nextDayValue != null) {
        nextDay = Date(nextDayValue);
      } else {
        nextDay = getNextByProgress(Date(todayLearnCreateDate).toDateTime(), nextProgress);
      }
      await setPrgAndNext4Sop(segmentKeyId, nextProgress, nextDay);
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

  static Date getNextByProgress(DateTime now, int nextProgress) {
    var forgettingCurve = scheduleConfig.forgettingCurve;
    if (nextProgress >= forgettingCurve.length - 1) {
      return getNext(now, forgettingCurve.last);
    } else {
      return getNext(now, forgettingCurve[nextProgress]);
    }
  }

  static Date getNext(DateTime now, int seconds) {
    var a = Date.from(now);
    var b = Date.from(now.add(Duration(seconds: seconds)));
    if (a.value == b.value) {
      return Date.from(now.add(const Duration(days: 1)));
    } else {
      return b;
    }
  }
}
