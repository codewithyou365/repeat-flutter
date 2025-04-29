// dao/schedule_dao.dart

import 'dart:convert' as convert;

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/doc.dart';
import 'package:repeat_flutter/db/entity/segment.dart';
import 'package:repeat_flutter/db/entity/lesson.dart';
import 'package:repeat_flutter/db/entity/lesson_key.dart';
import 'package:repeat_flutter/db/entity/segment_key.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';
import 'package:repeat_flutter/db/entity/segment_review.dart';
import 'package:repeat_flutter/db/entity/text_version.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/model/repeat_doc.dart' as rd;
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/logic/model/segment_key_id.dart';
import 'package:repeat_flutter/logic/model/segment_overall_prg_with_key.dart';
import 'package:repeat_flutter/logic/model/segment_review_with_key.dart';
import 'package:repeat_flutter/db/entity/segment_stats.dart';
import 'package:repeat_flutter/logic/model/segment_show.dart';
import 'package:repeat_flutter/logic/repeat_doc_edit_help.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

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
  late AppDatabase db;

  static SegmentShow? Function(int segmentKeyId)? getSegmentShow;
  static List<void Function(int segmentKeyId)> setSegmentShowContent = [];
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

  @Query('SELECT * FROM Doc WHERE id=:id')
  Future<Doc?> getDocById(int id);

  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  @Query('UPDATE Content set hide=true,docId=0'
      ' WHERE Content.id=:id')
  Future<void> hideContent(int id);

  /// --- CrKv ---

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

  /// --- Update SegmentKey ---
  @Query('UPDATE SegmentKey set note=:note,noteVersion=:noteVersion WHERE id=:id')
  Future<void> updateSegmentNote(int id, String note, int noteVersion);

  @Query('UPDATE SegmentKey set k=:key,content=:content,contentVersion=:contentVersion WHERE id=:id')
  Future<void> updateSegmentKeyAndContent(int id, String key, String content, int contentVersion);

  @Query('SELECT note FROM SegmentKey WHERE id=:id')
  Future<String?> getSegmentNote(int id);

  /// --- SegmentTodayPrg ---

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
      ",Lesson.lessonKeyId"
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
      " JOIN Lesson ON Lesson.classroomId=:classroomId"
      "  AND Lesson.contentSerial=Segment.contentSerial"
      "  AND Lesson.lessonIndex=Segment.lessonIndex"
      " WHERE SegmentReview.classroomId=:classroomId"
      " AND SegmentReview.count=:reviewCount"
      " AND SegmentReview.createDate=:startDate"
      " ORDER BY Segment.sort")
  Future<List<SegmentTodayPrg>> scheduleReview(int classroomId, int reviewCount, Date startDate);

  @Query("SELECT * FROM ("
      " SELECT"
      " Segment.classroomId"
      ",Segment.contentSerial"
      ",Lesson.lessonKeyId"
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
      " JOIN Segment ON Segment.segmentKeyId=SegmentOverallPrg.segmentKeyId"
      "  AND Segment.classroomId=:classroomId"
      " JOIN Lesson ON Lesson.classroomId=:classroomId"
      "  AND Lesson.contentSerial=Segment.contentSerial"
      "  AND Lesson.lessonIndex=Segment.lessonIndex"
      " WHERE SegmentOverallPrg.next<=:now"
      "  AND SegmentOverallPrg.progress>=:minProgress"
      " ORDER BY SegmentOverallPrg.progress,Segment.sort"
      " ) Segment order by Segment.sort")
  Future<List<SegmentTodayPrg>> scheduleLearn(int classroomId, int minProgress, Date now);

  @Query("SELECT"
      " Segment.classroomId"
      ",Segment.contentSerial"
      ",Lesson.lessonKeyId"
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
      " JOIN Lesson ON Lesson.classroomId=:classroomId"
      "  AND Lesson.contentSerial=Segment.contentSerial"
      "  AND Lesson.lessonIndex=Segment.lessonIndex"
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

  @Query("SELECT progress FROM SegmentOverallPrg WHERE segmentKeyId=:segmentKeyId")
  Future<int?> getSegmentProgress(int segmentKeyId);

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

  @Update()
  Future<void> updateSegmentKeys(List<SegmentKey> entities);

  @Query('SELECT SegmentKey.id'
      ',SegmentKey.k FROM SegmentKey'
      ' WHERE SegmentKey.classroomId=:classroomId'
      ' and SegmentKey.contentSerial=:contentSerial')
  Future<List<KeyId>> getSegmentKeyId(int classroomId, int contentSerial);

  @Query('SELECT SegmentKey.* FROM SegmentKey'
      ' WHERE SegmentKey.classroomId=:classroomId'
      ' AND SegmentKey.contentSerial=:contentSerial')
  Future<List<SegmentKey>> getSegmentKey(int classroomId, int contentSerial);

  @Query('SELECT SegmentKey.* FROM SegmentKey'
      ' WHERE SegmentKey.id=:id')
  Future<SegmentKey?> getSegmentKeyById(int id);

  @Query('SELECT SegmentKey.* FROM SegmentKey'
      ' WHERE SegmentKey.classroomId=:classroomId'
      ' AND SegmentKey.contentSerial=:contentSerial'
      ' AND SegmentKey.k=:key')
  Future<SegmentKey?> getSegmentKeyByKey(int classroomId, int contentSerial, String key);

  @Query('SELECT SegmentKey.id segmentKeyId'
      ',SegmentKey.k'
      ',Content.id contentId'
      ',Content.name contentName'
      ',Content.serial contentSerial'
      ',Content.sort contentSort'
      ',SegmentKey.content segmentContent'
      ',SegmentKey.contentVersion segmentContentVersion'
      ',SegmentKey.note segmentNote'
      ',SegmentKey.noteVersion segmentNoteVersion'
      ',SegmentKey.lessonIndex'
      ',SegmentKey.segmentIndex'
      ',SegmentOverallPrg.next'
      ',SegmentOverallPrg.progress'
      ',Segment.segmentKeyId is null missing'
      ' FROM SegmentKey'
      " JOIN Content ON Content.classroomId=:classroomId AND Content.docId!=0"
      ' LEFT JOIN Segment ON Segment.segmentKeyId=SegmentKey.id'
      ' LEFT JOIN SegmentOverallPrg ON SegmentOverallPrg.segmentKeyId=SegmentKey.id'
      ' WHERE SegmentKey.classroomId=:classroomId')
  Future<List<SegmentShow>> getAllSegment(int classroomId);

  @Query('SELECT SegmentKey.id segmentKeyId'
      ',SegmentKey.k'
      ',Content.id contentId'
      ',Content.name contentName'
      ',Content.serial contentSerial'
      ',Content.sort contentSort'
      ',SegmentKey.content segmentContent'
      ',SegmentKey.contentVersion segmentContentVersion'
      ',SegmentKey.note segmentNote'
      ',SegmentKey.noteVersion segmentNoteVersion'
      ',SegmentKey.lessonIndex'
      ',SegmentKey.segmentIndex'
      ',SegmentOverallPrg.next'
      ',SegmentOverallPrg.progress'
      ',Segment.segmentKeyId is null missing'
      ' FROM SegmentKey'
      " JOIN Content ON Content.classroomId=:classroomId AND Content.docId!=0"
      ' LEFT JOIN Segment ON Segment.segmentKeyId=SegmentKey.id'
      ' LEFT JOIN SegmentOverallPrg ON SegmentOverallPrg.segmentKeyId=SegmentKey.id'
      ' WHERE SegmentKey.classroomId=:classroomId'
      '  AND SegmentKey.contentSerial=:contentSerial'
      '  AND SegmentKey.lessonIndex=:lessonIndex')
  Future<List<SegmentShow>> getLessonSegment(int classroomId, int contentSerial, int lessonIndex);

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

  @Query('SELECT ifnull(max(SegmentStats.id),0) FROM SegmentStats'
      ' WHERE SegmentStats.classroomId=:classroomId')
  Future<int?> getMaxSegmentStatsId(int classroomId);

  @Query('SELECT ifnull(max(Content.updateTime),0) FROM Content'
      ' WHERE Content.classroomId=:classroomId')
  Future<int?> getMaxContentUpdateTime(int classroomId);

  /// SegmentText start

  @Query('SELECT TextVersion.* '
      ' FROM SegmentKey'
      ' JOIN TextVersion ON TextVersion.t=0'
      '  AND TextVersion.id=SegmentKey.id'
      '  AND TextVersion.version=SegmentKey.contentVersion'
      ' WHERE SegmentKey.id in (:ids)')
  Future<List<TextVersion>> getSegmentTextForContent(List<int> ids);

  @Query('SELECT TextVersion.* '
      ' FROM SegmentKey'
      ' JOIN TextVersion ON TextVersion.t=1'
      '  AND TextVersion.id=SegmentKey.id'
      '  AND TextVersion.version=SegmentKey.noteVersion'
      ' WHERE SegmentKey.id in (:ids)')
  Future<List<TextVersion>> getSegmentTextForNote(List<int> ids);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertSegmentTextVersions(List<TextVersion> entities);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertSegmentTextVersion(TextVersion entity);

  /// SegmentText end

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSegmentStats(SegmentStats stats);

  @transaction
  Future<void> deleteAbnormalSegment(int segmentKeyId) async {
    await forUpdate();
    await deleteSegment(segmentKeyId);
    await deleteSegmentKey(segmentKeyId);
    await deleteSegmentOverallPrg(segmentKeyId);
    await deleteSegmentReview(segmentKeyId);
    await deleteSegmentTodayPrg(segmentKeyId);
    await db.textVersionDao.delete(TextVersionType.segmentContent, segmentKeyId);
    await db.textVersionDao.delete(TextVersionType.segmentNote, segmentKeyId);
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

  /// for content
  String getKey(String? key, String answer) {
    var ret = "";
    if (key != null && key.isNotEmpty) {
      ret = key;
    }
    if (ret.isEmpty) {
      ret = answer;
    }
    return ret;
  }

  Future<bool> prepareImportSegment(
    List<String> contentJson,
    List<Lesson> lessons,
    List<LessonKey> lessonKeys,
    List<SegmentKey> segmentKeys,
    List<Segment> segments,
    List<SegmentOverallPrg> segmentOverallPrgs, {
    int contentId = 0,
    int contentSerial = 0,
    int? indexJsonDocId,
    String? url,
  }) async {
    Content? content;
    if (contentId != 0) {
      content = await db.contentDao.getById(contentId);
    } else if (contentSerial != 0) {
      content = await db.contentDao.getBySerial(Classroom.curr, contentSerial);
    }
    if (content == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["content"]));
      return false;
    }
    var doc = await getDocById(indexJsonDocId ?? content.docId);
    if (doc == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["doc"]));
      return false;
    }
    Map<String, dynamic>? jsonData = await DocHelp.toJsonMap(DocPath.getRelativeIndexPath(content.serial));
    if (jsonData == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["jsonData"]));
      return false;
    }
    var kv = rd.RepeatDoc.fromJson(jsonData);
    if (kv.lesson.length >= 100000) {
      Snackbar.show(I18nKey.labelTooMuchData.trArgs(["lesson"]));
      return false;
    }
    for (var d in kv.lesson) {
      if (d.segment.length >= 100000) {
        Snackbar.show(I18nKey.labelTooMuchData.trArgs(["segment"]));
        return false;
      }
    }
    Map<String, bool> segmentKey = {};
    var now = DateTime.now();

    Map<String, dynamic> excludeLesson = {};
    jsonData.forEach((k, v) {
      if (k != 'l') {
        excludeLesson[k] = v;
      }
    });
    contentJson.add(convert.jsonEncode(excludeLesson));

    List<dynamic> rawLessons = jsonData['l'] as List<dynamic>;
    for (var lessonIndex = 0; lessonIndex < kv.lesson.length; lessonIndex++) {
      Map<String, dynamic> rawLesson = rawLessons[lessonIndex] as Map<String, dynamic>;
      Map<String, dynamic> excludeSegment = {};
      rawLesson.forEach((k, v) {
        if (k != 's') {
          excludeSegment[k] = v;
        }
      });
      String lessonContent = convert.jsonEncode(excludeSegment);

      var lesson = kv.lesson[lessonIndex];
      lessons.add(Lesson(
        classroomId: content.classroomId,
        contentSerial: content.serial,
        lessonIndex: lessonIndex,
      ));
      lessonKeys.add(LessonKey(
        classroomId: content.classroomId,
        contentSerial: content.serial,
        lessonIndex: lessonIndex,
        version: 1,
        content: lessonContent,
        contentVersion: 1,
      ));
      List<dynamic> rawSegments = rawLesson['s'] as List<dynamic>;
      for (var segmentIndex = 0; segmentIndex < lesson.segment.length; segmentIndex++) {
        var rawSegment = rawSegments[segmentIndex] as Map<String, dynamic>;
        var segment = lesson.segment[segmentIndex];
        if (segment.answer.isEmpty) {
          Snackbar.show(I18nKey.labelSegmentNeedToContainAnswer.tr);
          return false;
        }
        var key = getKey(segment.key, segment.answer);
        if (segmentKey.containsKey(key)) {
          Snackbar.show(I18nKey.labelSegmentKeyDuplicated.trArgs([key]));
          return false;
        }
        segmentKey[key] = true;
        Map<String, dynamic> excludeNote = {};
        rawSegment.forEach((k, v) {
          if (k != 'n') {
            excludeNote[k] = v;
          }
        });
        String segmentContent = convert.jsonEncode(excludeNote);
        segmentKeys.add(SegmentKey(
          classroomId: content.classroomId,
          contentSerial: content.serial,
          lessonIndex: lessonIndex,
          segmentIndex: segmentIndex,
          version: 1,
          k: key,
          content: segmentContent,
          contentVersion: 1,
          note: segment.note ?? '',
          noteVersion: 1,
        ));
        segments.add(Segment(
          0,
          content.classroomId,
          content.serial,
          lessonIndex,
          segmentIndex,
          //4611686118427387904-(99999*10000000000+99999*100000+99999)
          content.sort * 10000000000 + lessonIndex * 100000 + segmentIndex,
        ));
        segmentOverallPrgs.add(SegmentOverallPrg(0, content.classroomId, content.serial, Date.from(now), 0));
      }
    }
    return true;
  }

  List<TextVersion> toNeedToInsertSegmentText(
    List<SegmentKey> newSegmentKeys,
    TextVersionType segmentTextVersionType,
    Map<int, TextVersion> segmentKeyIdToVersion,
    String Function(SegmentKey) getText,
  ) {
    List<TextVersion> needToInsert = [];

    for (var v in newSegmentKeys) {
      TextVersion? version = segmentKeyIdToVersion[v.id!];
      String text = getText(v);
      if (version == null || version.text != text) {
        int currVersionNumber = 1;
        if (version != null) {
          currVersionNumber = version.version + 1;
        }
        var stv = TextVersion(
          t: segmentTextVersionType,
          id: v.id!,
          version: currVersionNumber,
          reason: TextVersionReason.import,
          text: text,
          createTime: DateTime.now(),
        );
        needToInsert.add(stv);
      }
    }
    return needToInsert;
  }

  @transaction
  Future<int> importSegment(
    int contentId,
    int contentSerial,
    int? indexJsonDocId,
    String? url,
  ) async {
    await forUpdate();
    List<String> newContents = [];
    List<Lesson> newLessons = [];
    List<LessonKey> newLessonKeys = [];
    List<SegmentKey> newSegmentKeys = [];
    List<Segment> segments = [];
    List<SegmentOverallPrg> segmentOverallPrgs = [];
    bool success = await prepareImportSegment(
      newContents,
      newLessons,
      newLessonKeys,
      newSegmentKeys,
      segments,
      segmentOverallPrgs,
      contentId: contentId,
      contentSerial: contentSerial,
      indexJsonDocId: indexJsonDocId,
      url: url,
    );
    if (!success) {
      return ImportResult.error.index;
    }
    if (contentSerial == 0) {
      for (var segmentKey in newSegmentKeys) {
        contentSerial = segmentKey.contentSerial;
        break;
      }
    }

    List<SegmentKey> oldSegmentKeys = await getSegmentKey(Classroom.curr, contentSerial);
    var maxVersion = 0;
    Map<String, SegmentKey> keyToOldSegmentKey = {};
    Map<String, int> keyToId = {};
    List<int> oldSegmentKeyIds = [];
    for (var oldSegmentKey in oldSegmentKeys) {
      if (oldSegmentKey.version > maxVersion) {
        maxVersion = oldSegmentKey.version;
      }
      keyToOldSegmentKey[oldSegmentKey.k] = oldSegmentKey;
      keyToId[oldSegmentKey.k] = oldSegmentKey.id!;
      oldSegmentKeyIds.add(oldSegmentKey.id!);
    }
    var nextVersion = maxVersion + 1;
    Map<int, SegmentKey> needToModifyMap = {};
    List<SegmentKey> needToInsert = [];
    for (var newSegmentKey in newSegmentKeys) {
      newSegmentKey.version = nextVersion;
      SegmentKey? oldSegmentKey = keyToOldSegmentKey[newSegmentKey.k];
      if (oldSegmentKey == null) {
        needToInsert.add(newSegmentKey);
      } else {
        newSegmentKey.id = oldSegmentKey.id;
        newSegmentKey.contentVersion = oldSegmentKey.contentVersion;
        newSegmentKey.noteVersion = oldSegmentKey.noteVersion;
        if (oldSegmentKey.lessonIndex != newSegmentKey.lessonIndex || //
            oldSegmentKey.segmentIndex != newSegmentKey.segmentIndex || //
            oldSegmentKey.content != newSegmentKey.content || //
            oldSegmentKey.note != newSegmentKey.note) {
          needToModifyMap[oldSegmentKey.id!] = newSegmentKey;
        }
      }
    }
    if (needToInsert.isNotEmpty) {
      await insertSegmentKeys(needToInsert);
      var keyIds = await getSegmentKeyId(Classroom.curr, contentSerial);
      keyToId = {for (var keyId in keyIds) keyId.k: keyId.id};
      for (var newSegmentKey in newSegmentKeys) {
        int? id = keyToId[newSegmentKey.k];
        if (id != null) {
          newSegmentKey.id = id;
        }
      }
    }

    List<TextVersion> oldContentVersion = await getSegmentTextForContent(oldSegmentKeyIds);
    Map<int, TextVersion> oldSegmentKeyIdToContentVersion = {for (var v in oldContentVersion) v.id: v};
    var needToInsertSegmentContent = toNeedToInsertSegmentText(newSegmentKeys, TextVersionType.segmentContent, oldSegmentKeyIdToContentVersion, (v) => v.content);
    Map<int, TextVersion> newSegmentKeyIdToContentVersion = {for (var v in needToInsertSegmentContent) v.id: v};
    List<TextVersion> oldNoteVersion = await getSegmentTextForNote(oldSegmentKeyIds);
    Map<int, TextVersion> oldSegmentKeyIdToNoteVersion = {for (var v in oldNoteVersion) v.id: v};
    var needToInsertSegmentNote = toNeedToInsertSegmentText(newSegmentKeys, TextVersionType.segmentNote, oldSegmentKeyIdToNoteVersion, (v) => v.note);
    Map<int, TextVersion> newSegmentKeyIdToNoteVersion = {for (var v in needToInsertSegmentNote) v.id: v};
    for (var i = 0; i < newSegmentKeys.length; i++) {
      SegmentKey newSegmentKey = newSegmentKeys[i];
      var id = keyToId[newSegmentKey.k]!;
      var contentVersion = newSegmentKeyIdToContentVersion[id];
      if (contentVersion != null && newSegmentKey.contentVersion != contentVersion.version) {
        newSegmentKey.contentVersion = contentVersion.version;
        needToModifyMap[newSegmentKey.id!] = newSegmentKey;
      }
      var noteVersion = newSegmentKeyIdToNoteVersion[id];
      if (noteVersion != null && newSegmentKey.noteVersion != noteVersion.version) {
        newSegmentKey.noteVersion = noteVersion.version;
        needToModifyMap[newSegmentKey.id!] = newSegmentKey;
      }
      segments[i].segmentKeyId = id;
      segmentOverallPrgs[i].segmentKeyId = id;
    }
    await deleteSegmentByContentSerial(Classroom.curr, contentSerial);
    await insertSegments(segments);
    await insertSegmentOverallPrgs(segmentOverallPrgs);
    if (needToInsertSegmentContent.isNotEmpty) {
      await insertSegmentTextVersions(needToInsertSegmentContent);
    }
    if (needToInsertSegmentNote.isNotEmpty) {
      await insertSegmentTextVersions(needToInsertSegmentNote);
    }
    if (needToModifyMap.isNotEmpty) {
      await updateSegmentKeys(needToModifyMap.values.toList());
    }
    await db.contentDao.import(contentSerial, newContents[0]);
    var warningInLesson = await db.lessonKeyDao.import(newLessons, newLessonKeys, contentSerial);
    var warningInSegment = segments.length < keyToId.length;

    if (indexJsonDocId != null && url != null) {
      await db.contentDao.updateContent(contentId, indexJsonDocId, url, warningInLesson, warningInSegment, DateTime.now().millisecondsSinceEpoch);
    } else {
      await db.contentDao.updateContentWarning(contentId, warningInLesson, warningInSegment, DateTime.now().millisecondsSinceEpoch);
    }
    if (warningInLesson == true || warningInSegment == true) {
      return ImportResult.successButSomeSegmentsAreSurplus.index;
    } else {
      return ImportResult.success.index;
    }
  }

  @transaction
  Future<bool> deleteNormalSegment(int segmentKeyId) async {
    await forUpdate();
    var raw = await db.segmentKeyDao.oneById(segmentKeyId);
    if (raw == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["cant find the data($segmentKeyId)"]));
      return false;
    }
    int classroomId = raw.classroomId;
    int segmentIndex = raw.segmentIndex;
    var segments = await db.segmentDao.findByMinSegmentIndex(classroomId, raw.contentSerial, raw.lessonIndex, segmentIndex);
    var segmentKeys = await db.segmentKeyDao.findByMinSegmentIndex(classroomId, raw.contentSerial, raw.lessonIndex, segmentIndex);
    List<Segment> insertSegments = [];
    List<SegmentKey> insertSegmentKeys = [];
    for (var v in segments) {
      v.segmentIndex--;
      v.sort--;
      if (v.segmentKeyId != segmentKeyId) {
        insertSegments.add(v);
      }
    }
    for (var v in segmentKeys) {
      v.segmentIndex--;
      if (v.id != segmentKeyId) {
        insertSegmentKeys.add(v);
      }
    }
    await db.segmentDao.deleteByMinSegmentIndex(classroomId, raw.contentSerial, raw.lessonIndex, segmentIndex);
    await db.segmentKeyDao.deleteByMinSegmentIndex(classroomId, raw.contentSerial, raw.lessonIndex, segmentIndex);
    await db.segmentDao.insertListOrFail(insertSegments);
    await db.segmentKeyDao.insertListOrFail(insertSegmentKeys);
    await deleteSegmentOverallPrg(segmentKeyId);
    await deleteSegmentReview(segmentKeyId);
    await deleteSegmentTodayPrg(segmentKeyId);
    await db.textVersionDao.delete(TextVersionType.segmentContent, segmentKeyId);
    await db.textVersionDao.delete(TextVersionType.segmentNote, segmentKeyId);
    return true;
  }

  @transaction
  Future<int> addSegment(SegmentShow raw, int segmentIndex) async {
    await forUpdate();
    String content = "";
    String key = "";
    Map<String, dynamic> contentMap;
    try {
      contentMap = convert.jsonDecode(raw.segmentContent);
      if (contentMap['k'] == null || contentMap['k'].toString().isEmpty) {
        if (contentMap['a'] != null && contentMap['a'].toString().isNotEmpty) {
          contentMap['k'] = '${contentMap['a']}_${DateTime.now().millisecondsSinceEpoch}';
        } else {
          contentMap['k'] = 'segment_${DateTime.now().millisecondsSinceEpoch}';
        }
      } else {
        contentMap['k'] = '${contentMap['k']}_${DateTime.now().millisecondsSinceEpoch}';
      }
      content = convert.jsonEncode(contentMap);
      key = contentMap['k'].toString();
    } catch (e) {
      return 0;
    }
    int classroomId = Classroom.curr;
    var existingSegment = await getSegmentKeyByKey(classroomId, raw.contentSerial, key);
    if (existingSegment != null) {
      Snackbar.show(I18nKey.labelSegmentKeyDuplicated.trArgs([key]));
      return 0;
    }

    // adjust the segment index and sort
    var segments = await db.segmentDao.findByMinSegmentIndex(classroomId, raw.contentSerial, raw.lessonIndex, segmentIndex);
    var segmentKeys = await db.segmentKeyDao.findByMinSegmentIndex(classroomId, raw.contentSerial, raw.lessonIndex, segmentIndex);
    for (var v in segments) {
      v.segmentIndex++;
      v.sort++;
    }
    for (var v in segmentKeys) {
      v.segmentIndex++;
    }
    await db.segmentDao.deleteByMinSegmentIndex(classroomId, raw.contentSerial, raw.lessonIndex, segmentIndex);
    await db.segmentKeyDao.deleteByMinSegmentIndex(classroomId, raw.contentSerial, raw.lessonIndex, segmentIndex);

    // insert and get the segment key id
    SegmentKey? segmentKey = SegmentKey(
      classroomId: classroomId,
      contentSerial: raw.contentSerial,
      lessonIndex: raw.lessonIndex,
      segmentIndex: segmentIndex,
      version: 1,
      k: key,
      content: content,
      contentVersion: 1,
      note: '',
      noteVersion: 1,
    );
    segmentKeys.add(segmentKey);
    await db.segmentKeyDao.insertListOrFail(segmentKeys);
    segmentKey = await getSegmentKeyByKey(segmentKey.classroomId, segmentKey.contentSerial, key);
    if (segmentKey == null) {
      throw Exception('Failed to get segment key');
    }

    int sortValue = segmentKey.contentSerial * 10000000000 + segmentKey.lessonIndex * 100000 + segmentIndex;
    var segment = Segment(segmentKey.id!, segmentKey.classroomId, segmentKey.contentSerial, segmentKey.lessonIndex, segmentKey.segmentIndex, sortValue);
    segments.add(segment);
    await db.segmentDao.insertListOrFail(segments);
    var now = DateTime.now();
    var segmentOverallPrg = SegmentOverallPrg(segmentKey.id!, segmentKey.classroomId, segmentKey.contentSerial, Date.from(now), 0);
    await db.segmentOverallPrgDao.insertOrFail(segmentOverallPrg);
    await db.textVersionDao.insertOrFail(TextVersion(
      t: TextVersionType.segmentContent,
      id: segmentKey.id!,
      version: 1,
      reason: TextVersionReason.editor,
      text: segmentKey.content,
      createTime: now,
    ));

    await db.textVersionDao.insertOrFail(TextVersion(
      t: TextVersionType.segmentNote,
      id: segmentKey.id!,
      version: 1,
      reason: TextVersionReason.editor,
      text: segmentKey.note,
      createTime: now,
    ));

    await insertKv(CrKv(segmentKey.classroomId, CrK.updateSegmentShowTime, now.millisecondsSinceEpoch.toString()));

    return segmentKey.id!;
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
  Future<void> tUpdateSegmentContent(int segmentKeyId, String content) async {
    SegmentKey? segmentKey = await getSegmentKeyById(segmentKeyId);
    if (segmentKey == null) {
      Snackbar.show(I18nKey.labelNotFoundSegment.trArgs([segmentKeyId.toString()]));
      return;
    }
    dynamic contentM;
    try {
      contentM = convert.jsonDecode(content);
      content = convert.jsonEncode(contentM);
    } catch (e) {
      Snackbar.show(e.toString());
      return;
    }

    if (segmentKey.content == content) {
      return;
    }
    String key;
    try {
      rd.Segment segment = rd.Segment.fromJson(contentM);
      key = getKey(segment.key, segment.answer);
    } catch (e) {
      Snackbar.show(e.toString());
      return;
    }
    if (key.isEmpty) {
      Snackbar.show(I18nKey.labelSegmentKeyCantBeEmpty.tr);
      return;
    }

    var otherSegmentKey = await getSegmentKeyByKey(segmentKey.classroomId, segmentKey.contentSerial, key);
    if (otherSegmentKey != null && otherSegmentKey.id != segmentKey.id) {
      Snackbar.show(I18nKey.labelSegmentKeyDuplicated.trArgs([key]));
      return;
    }
    // TODO the repeat doc is only used to import
    var ok = await RepeatDocEditHelp.setSegment(segmentKey.contentSerial, segmentKey.lessonIndex, segmentKey.segmentIndex, content);
    if (!ok) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(['997']));
      return;
    }
    var now = DateTime.now();
    await updateSegmentKeyAndContent(segmentKeyId, key, content, segmentKey.contentVersion + 1);
    await insertSegmentTextVersion(TextVersion(
      t: TextVersionType.segmentContent,
      id: segmentKeyId,
      version: segmentKey.contentVersion + 1,
      reason: TextVersionReason.editor,
      text: content,
      createTime: now,
    ));
    await insertKv(CrKv(Classroom.curr, CrK.updateSegmentShowTime, now.millisecondsSinceEpoch.toString()));
    if (getSegmentShow != null) {
      SegmentShow? currSegmentShow = getSegmentShow!(segmentKeyId);
      if (currSegmentShow != null) {
        currSegmentShow.segmentContent = content;
        for (var set in setSegmentShowContent) {
          set(segmentKeyId);
        }
        currSegmentShow.k = key;
        currSegmentShow.segmentContentVersion++;
      }
    }
  }

  @transaction
  Future<void> tUpdateSegmentNote(int segmentKeyId, String note) async {
    SegmentKey? segmentKey = await getSegmentKeyById(segmentKeyId);
    if (segmentKey == null) {
      Snackbar.show(I18nKey.labelNotFoundSegment.trArgs([segmentKeyId.toString()]));
      return;
    }
    if (segmentKey.note == note) {
      return;
    }
    var now = DateTime.now();
    await updateSegmentNote(segmentKeyId, note, segmentKey.noteVersion + 1);
    await insertSegmentTextVersion(TextVersion(
      t: TextVersionType.segmentNote,
      id: segmentKeyId,
      version: segmentKey.noteVersion + 1,
      reason: TextVersionReason.editor,
      text: note,
      createTime: now,
    ));
    await insertKv(CrKv(Classroom.curr, CrK.updateSegmentShowTime, now.millisecondsSinceEpoch.toString()));
    if (getSegmentShow != null) {
      SegmentShow? currSegmentShow = getSegmentShow!(segmentKeyId);
      if (currSegmentShow != null) {
        currSegmentShow.segmentNote = note;
        currSegmentShow.segmentNoteVersion++;
      }
    }
  }

  /// adjust progress start

  Future<Date> getTodayLearnCreateDate(DateTime now) async {
    var todayLearnCreateDate = await intKv(Classroom.curr, CrK.todayScheduleCreateDate);
    todayLearnCreateDate ??= Date.from(now).value;
    return Date(todayLearnCreateDate);
  }

  int getPrgTypeInt(SegmentTodayPrg segmentTodayPrg) {
    return getPrgType(segmentTodayPrg).index;
  }

  TodayPrgType getPrgType(SegmentTodayPrg segmentTodayPrg) {
    TodayPrgType prgType = TodayPrgType.none;
    if (segmentTodayPrg.reviewCreateDate.value == 0) {
      prgType = TodayPrgType.learn;
    } else if (segmentTodayPrg.reviewCreateDate.value == 1) {
      prgType = TodayPrgType.fullCustom;
    } else {
      prgType = TodayPrgType.review;
    }
    return prgType;
  }

  Future<void> setPrg(int segmentKeyId, int progress, Date? next) async {
    if (next != null) {
      await setPrgAndNext4Sop(segmentKeyId, progress, next);
    } else {
      await setPrg4Sop(segmentKeyId, progress);
    }
    var now = DateTime.now();
    await insertKv(CrKv(Classroom.curr, CrK.updateSegmentShowTime, now.millisecondsSinceEpoch.toString()));
    if (getSegmentShow != null) {
      SegmentShow? currSegmentShow = getSegmentShow!(segmentKeyId);
      if (currSegmentShow != null) {
        currSegmentShow.progress = progress;
        if (next != null) {
          currSegmentShow.next = next;
        }
      }
    }
  }

  @transaction
  Future<void> error(SegmentTodayPrg stp) async {
    await forUpdate();
    var now = DateTime.now();
    await setTodayPrgWithCache(stp, 0, now);
    await setPrg(stp.segmentKeyId, 0, null);
  }

  @transaction
  Future<void> jumpDirectly(int segmentKeyId, int progress, int nextDayValue) async {
    await forUpdate();
    await setPrg(segmentKeyId, progress, Date(nextDayValue));
  }

  @transaction
  Future<void> jump(SegmentTodayPrg stp, int progress, int nextDayValue) async {
    await forUpdate();

    TodayPrgType prgType = getPrgType(stp);

    var now = DateTime.now();
    var todayLearnCreateDate = await getTodayLearnCreateDate(now);

    if (prgType == TodayPrgType.learn) {
      await insertSegmentReview([SegmentReview(todayLearnCreateDate, stp.segmentKeyId, Classroom.curr, stp.contentSerial, 0)]);
    } else if (prgType == TodayPrgType.review) {
      await setSegmentReviewCount(stp.reviewCreateDate, stp.segmentKeyId, stp.reviewCount + 1);
    }

    await setPrg(stp.segmentKeyId, progress, Date(nextDayValue));
    await setTodayPrgWithCache(stp, scheduleConfig.maxRepeatTime, now);
    await insertSegmentStats(SegmentStats(stp.segmentKeyId, getPrgTypeInt(stp), todayLearnCreateDate, now.millisecondsSinceEpoch, Classroom.curr, stp.contentSerial));
  }

  @transaction
  Future<void> right(SegmentTodayPrg stp) async {
    await forUpdate();

    TodayPrgType prgType = getPrgType(stp);

    ProgressState state = ProgressState.unfinished;
    if (stp.progress == 0 && DateTime.fromMicrosecondsSinceEpoch(0).compareTo(stp.viewTime) == 0) {
      state = ProgressState.familiar;
    } else if (stp.progress + 1 >= scheduleConfig.maxRepeatTime) {
      state = ProgressState.unfamiliar;
    }

    var now = DateTime.now();
    Date todayLearnCreateDate = await getTodayLearnCreateDate(now);

    if (state == ProgressState.unfinished) {
      await setTodayPrgWithCache(stp, stp.progress + 1, now);
    } else {
      if (prgType == TodayPrgType.learn) {
        int nextProgress = 0;
        if (state == ProgressState.familiar) {
          var segmentProgress = await getSegmentProgress(stp.segmentKeyId);
          if (segmentProgress == null) {
            return;
          }
          nextProgress = segmentProgress + 1;
        }
        await setPrg(stp.segmentKeyId, nextProgress, getNextByProgress(todayLearnCreateDate.toDateTime(), nextProgress));
        await insertSegmentReview([SegmentReview(todayLearnCreateDate, stp.segmentKeyId, Classroom.curr, stp.contentSerial, 0)]);
      } else if (prgType == TodayPrgType.review) {
        await setSegmentReviewCount(stp.reviewCreateDate, stp.segmentKeyId, stp.reviewCount + 1);
      }
      await setTodayPrgWithCache(stp, scheduleConfig.maxRepeatTime, now);
      await insertSegmentStats(SegmentStats(stp.segmentKeyId, prgType.index, todayLearnCreateDate, now.millisecondsSinceEpoch, Classroom.curr, stp.contentSerial));
    }
  }

  Future<void> setTodayPrgWithCache(SegmentTodayPrg segmentTodayPrg, int progress, DateTime now) async {
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

  /// adjust progress end
}
