// dao/schedule_dao.dart

import 'dart:convert' as convert;

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/db/dao/verse_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/verse.dart';
import 'package:repeat_flutter/db/entity/verse_review.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/model/verse_review_with_key.dart';
import 'package:repeat_flutter/db/entity/verse_stats.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';

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

  String tr() {
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

  String trWithTitle() {
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

  String tr() {
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

  String trWithTitle() {
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

  /// --- Update VerseKey ---
  @Query('UPDATE VerseKey set note=:note,noteVersion=:noteVersion WHERE id=:id')
  Future<void> updateVerseNote(int id, String note, int noteVersion);

  @Query('UPDATE VerseKey set k=:key,content=:content,contentVersion=:contentVersion WHERE id=:id')
  Future<void> updateVerseKeyAndContent(int id, String key, String content, int contentVersion);

  @Query('SELECT note FROM VerseKey WHERE id=:id')
  Future<String?> getVerseNote(int id);

  /// --- VerseTodayPrg ---

  @Query('DELETE FROM VerseTodayPrg where classroomId=:classroomId and reviewCreateDate>100')
  Future<void> deleteVerseTodayReviewPrgByClassroomId(int classroomId);

  @Query('DELETE FROM VerseTodayPrg where classroomId=:classroomId and reviewCreateDate=0')
  Future<void> deleteVerseTodayLearnPrgByClassroomId(int classroomId);

  @Query('DELETE FROM VerseTodayPrg where classroomId=:classroomId and reviewCreateDate=1')
  Future<void> deleteVerseTodayFullCustomPrgByClassroomId(int classroomId);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertVerseTodayPrg(List<VerseTodayPrg> entities);

  @Query('SELECT *'
      ' FROM VerseTodayPrg'
      " WHERE classroomId=:classroomId"
      ' order by id asc')
  Future<List<VerseTodayPrg>> findVerseTodayPrg(int classroomId);

  @Query('UPDATE VerseTodayPrg SET progress=:progress,viewTime=:viewTime,finish=:finish WHERE verseId=:verseId and type=:type')
  Future<void> setVerseTodayPrg(int verseId, int type, int progress, DateTime viewTime, bool finish);

  @Query("SELECT IFNULL(MIN(VerseReview.createDate),-1) FROM VerseReview"
      " JOIN Verse ON Verse.id=VerseReview.verseId"
      " WHERE VerseReview.classroomId=:classroomId"
      " AND VerseReview.count=:reviewCount"
      " and VerseReview.createDate<=:now"
      " order by VerseReview.createDate")
  Future<int?> findReviewedMinCreateDate(int classroomId, int reviewCount, Date now);

  @Query("SELECT"
      " VerseReview.classroomId"
      ",Verse.bookId"
      ",Verse.chapterId"
      ",VerseReview.verseId"
      ",0 time"
      ",0 type"
      ",Verse.sort"
      ",0 progress"
      ",0 viewTime"
      ",VerseReview.count reviewCount"
      ",VerseReview.createDate reviewCreateDate"
      ",0 finish"
      " FROM VerseReview"
      " JOIN Verse ON Verse.id=VerseReview.verseId"
      " WHERE VerseReview.classroomId=:classroomId"
      " AND VerseReview.count=:reviewCount"
      " AND VerseReview.createDate=:startDate"
      " ORDER BY Verse.sort")
  Future<List<VerseTodayPrg>> scheduleReview(int classroomId, int reviewCount, Date startDate);

  @Query("SELECT * FROM ("
      " SELECT"
      " Verse.classroomId"
      ",Verse.bookId"
      ",Verse.chapterId"
      ",Verse.id verseId"
      ",0 time"
      ",0 type"
      ",Verse.sort"
      ",Verse.progress progress"
      ",0 viewTime"
      ",0 reviewCount"
      ",0 reviewCreateDate"
      ",0 finish"
      " FROM Verse"
      " WHERE Verse.nextLearnDate<=:now"
      "  AND Verse.progress>=:minProgress"
      " ORDER BY Verse.progress,Verse.sort"
      " ) Verse order by Verse.sort")
  Future<List<VerseTodayPrg>> scheduleLearn(int minProgress, Date now);

  @Query("SELECT"
      " Verse.classroomId"
      ",Verse.bookId"
      ",Verse.chapterId"
      ",Verse.id verseId"
      ",0 time"
      ",0 type"
      ",Verse.sort"
      ",0 progress"
      ",0 viewTime"
      ",0 reviewCount"
      ",1 reviewCreateDate"
      ",0 finish"
      " FROM Verse"
      " WHERE Verse.classroomId=:classroomId"
      " AND Verse.sort>=("
      "  SELECT Verse.sort FROM Verse"
      "  WHERE Verse.bookId=:bookId"
      "  AND Verse.chapterIndex=:chapterIndex"
      "  AND Verse.verseIndex=:verseIndex"
      ")"
      " ORDER BY Verse.sort"
      " limit :limit"
      "")
  Future<List<VerseTodayPrg>> scheduleFullCustom(int classroomId, int bookId, int chapterIndex, int verseIndex, int limit);

  @Query('UPDATE Verse SET progress=:progress,nextLearnDate=:nextLearnDate WHERE id=:verseId')
  Future<void> setPrgAndLearnDate4Sop(int verseId, int progress, Date nextLearnDate);

  @Query('UPDATE Verse SET progress=:progress WHERE id=:verseId')
  Future<void> setPrg4Sop(int verseId, int progress);

  @Query("SELECT progress FROM Verse WHERE id=:verseId")
  Future<int?> getVerseProgress(int verseId);

  /// --- VerseReview
  @Query("SELECT Book.name FROM Book WHERE Book.id=:bookId")
  Future<String?> getBookNameById(int bookId);

  @Query("SELECT VerseReview.*"
      ",Book.name contentName"
      ",Verse.chapterIndex"
      ",Verse.verseIndex"
      " FROM VerseReview"
      " JOIN Verse ON Verse.id=VerseReview.verseId"
      " JOIN Book ON Book.id=VerseReview.bookId"
      " WHERE VerseReview.classroomId=:classroomId"
      " AND VerseReview.createDate>=:start AND VerseReview.createDate<=:end"
      " ORDER BY VerseReview.createDate desc,Verse.sort asc")
  Future<List<VerseReviewWithKey>> getAllVerseReview(int classroomId, Date start, Date end);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertVerseReview(List<VerseReview> review);

  @Query('UPDATE VerseReview SET count=:count WHERE createDate=:createDate and `verseId`=:verseId')
  Future<void> setVerseReviewCount(Date createDate, int verseId, int count);

  @Query("SELECT LimitVerse.verseId"
      " FROM (SELECT sort,id verseId"
      "  FROM Verse"
      "  WHERE classroomId=:classroomId"
      "  AND sort<(SELECT Verse.sort FROM Verse WHERE Verse.id=:verseId)"
      "  ORDER BY sort desc"
      "  LIMIT :offset) LimitVerse"
      "  ORDER BY LimitVerse.sort"
      " LIMIT 1")
  Future<int?> getPrevVerseKeyIdWithOffset(int classroomId, int verseId, int offset);

  @Query("SELECT LimitVerse.verseId"
      " FROM (SELECT sort,id verseId"
      "  FROM Verse"
      "  WHERE classroomId=:classroomId"
      "  AND sort>(SELECT Verse.sort FROM Verse WHERE Verse.id=:verseId)"
      "  ORDER BY sort"
      "  LIMIT :offset) LimitVerse"
      "  ORDER BY LimitVerse.sort desc"
      " LIMIT 1")
  Future<int?> getNextVerseKeyIdWithOffset(int classroomId, int verseId, int offset);

  @Query('SELECT Verse.id verseId'
      ',Book.id bookId'
      ',Book.name bookName'
      ',Book.sort bookSort'
      ',Verse.content verseContent'
      ',Verse.contentVersion verseContentVersion'
      ',Verse.note verseNote'
      ',Verse.noteVersion verseNoteVersion'
      ',Verse.chapterId'
      ',Verse.chapterIndex'
      ',Verse.verseIndex'
      ',Verse.nextLearnDate'
      ',Verse.progress'
      ' FROM Verse'
      ' JOIN Book ON Book.id=Verse.bookId AND Book.enable=true'
      ' WHERE Verse.classroomId=:classroomId')
  Future<List<VerseShow>> getAllVerse(int classroomId);

  @Query('SELECT Verse.id verseId'
      ',Book.id bookId'
      ',Book.name bookName'
      ',Book.sort bookSort'
      ',Verse.content verseContent'
      ',Verse.contentVersion verseContentVersion'
      ',Verse.note verseNote'
      ',Verse.noteVersion verseNoteVersion'
      ',Verse.chapterId'
      ',Verse.chapterIndex'
      ',Verse.verseIndex'
      ',Verse.nextLearnDate'
      ',Verse.progress'
      ' FROM Verse'
      " JOIN Book ON Book.id=:bookId AND Book.enable=true"
      ' WHERE Verse.bookId=:bookId'
      '  AND Verse.chapterIndex=:chapterIndex')
  Future<List<VerseShow>> getVerseByChapterIndex(int bookId, int chapterIndex);

  @Query('SELECT Verse.id verseId'
      ',Book.id bookId'
      ',Book.name bookName'
      ',Book.sort bookSort'
      ',Verse.content verseContent'
      ',Verse.contentVersion verseContentVersion'
      ',Verse.note verseNote'
      ',Verse.noteVersion verseNoteVersion'
      ',Verse.chapterId'
      ',Verse.chapterIndex'
      ',Verse.verseIndex'
      ',Verse.nextLearnDate'
      ',Verse.progress'
      ' FROM Verse'
      " JOIN Book ON Book.id=Verse.bookId AND Book.enable=true"
      ' WHERE Verse.bookId=:bookId'
      '  AND Verse.chapterIndex>=:minChapterIndex')
  Future<List<VerseShow>> getVerseByMinChapterIndex(int bookId, int minChapterIndex);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertVerses(List<Verse> entities);

  @Query('DELETE FROM Verse WHERE id=:verseId')
  Future<void> deleteVerse(int verseId);

  @Query('DELETE FROM VerseReview WHERE verseId=:verseId')
  Future<void> deleteVerseReview(int verseId);

  @Query('DELETE FROM VerseTodayPrg WHERE verseId=:verseId')
  Future<void> deleteVerseTodayPrg(int verseId);

  @Query('SELECT ifnull(max(Verse.chapterIndex),0) FROM Verse'
      ' WHERE Verse.bookId=:bookId')
  Future<int?> getMaxChapterIndex(int bookId);

  @Query('SELECT ifnull(max(Verse.verseIndex),0) FROM Verse'
      ' WHERE Verse.bookId=:bookId'
      ' AND Verse.chapterIndex=:chapterIndex')
  Future<int?> getMaxVerseIndex(int bookId, int chapterIndex);

  @Query('SELECT ifnull(max(VerseStats.id),0) FROM VerseStats'
      ' WHERE VerseStats.classroomId=:classroomId')
  Future<int?> getMaxVerseStatsId(int classroomId);

  @Query('SELECT ifnull(max(Book.updateTime),0) FROM Book'
      ' WHERE Book.classroomId=:classroomId')
  Future<int?> getMaxBookUpdateTime(int classroomId);

  /// VerseText end

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertVerseStats(VerseStats stats);

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

  /// for progress
  @transaction
  Future<List<VerseTodayPrg>> initToday() async {
    await forUpdate();
    List<VerseTodayPrg> todayPrg = [];
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
      await db.verseTodayPrgDao.deleteByClassroomId(Classroom.curr);
      var elConfigs = scheduleConfig.elConfigs;
      await initTodayEl(now, elConfigs, todayPrg);
      var relConfigs = scheduleConfig.relConfigs;
      await initTodayRel(now, relConfigs, todayPrg);
      await insertVerseTodayPrg(todayPrg);
      var configInUseStr = convert.json.encode(scheduleConfig);
      await insertKv(CrKv(Classroom.curr, CrK.todayScheduleConfigInUse, configInUseStr));
    }
    todayPrg = await findVerseTodayPrg(Classroom.curr);
    return todayPrg;
  }

  @transaction
  Future<List<VerseTodayPrg>> forceInitToday(TodayPrgType type) async {
    scheduleConfig = await getScheduleConfigByKey(CrK.todayScheduleConfig);
    var scheduleConfigInUse = await getScheduleConfigByKey(CrK.todayScheduleConfigInUse);
    List<VerseTodayPrg> todayPrg = [];
    var now = DateTime.now();
    if (type == TodayPrgType.learn || type == TodayPrgType.none) {
      await deleteVerseTodayLearnPrgByClassroomId(Classroom.curr);
      var elConfigs = scheduleConfig.elConfigs;
      scheduleConfigInUse.elConfigs = elConfigs;
      await initTodayEl(now, elConfigs, todayPrg);
    }
    if (type == TodayPrgType.review || type == TodayPrgType.none) {
      await deleteVerseTodayReviewPrgByClassroomId(Classroom.curr);
      var relConfigs = scheduleConfig.relConfigs;
      scheduleConfigInUse.relConfigs = relConfigs;
      await initTodayRel(now, relConfigs, todayPrg);
    }
    if (type == TodayPrgType.fullCustom || type == TodayPrgType.none) {
      await deleteKv(CrKv(Classroom.curr, CrK.todayFullCustomScheduleConfigCount, ""));
      await deleteVerseTodayFullCustomPrgByClassroomId(Classroom.curr);
    }
    if (todayPrg.isNotEmpty) {
      await insertVerseTodayPrg(todayPrg);
    }
    var configInUseStr = convert.json.encode(scheduleConfigInUse);
    await insertKv(CrKv(Classroom.curr, CrK.todayScheduleConfigInUse, configInUseStr));

    return await findVerseTodayPrg(Classroom.curr);
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

  Future<void> initTodayEl(DateTime now, List<ElConfig> elConfigs, List<VerseTodayPrg> todayPrg) async {
    if (elConfigs.isNotEmpty) {
      int minLevel = (1 << 63) - 1;
      for (var config in elConfigs) {
        if (config.level < minLevel) {
          minLevel = config.level;
        }
      }
      var all = await scheduleLearn(minLevel, Date.from(now));
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

  Future<void> initTodayRel(DateTime now, List<RelConfig> relConfigs, List<VerseTodayPrg> todayPrg) async {
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
      List<VerseTodayPrg> sls = await scheduleReview(Classroom.curr, relConfig.level, shouldStartDate);
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
      VerseTodayPrg.setType(sls, TodayPrgType.review, index, relConfig.learnCountPerGroup);
      todayPrg.addAll(sls);
    }
  }

  List<VerseTodayPrg> refineEl(List<VerseTodayPrg> all, int index, ElConfig config) {
    List<VerseTodayPrg> curr;
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
    List<VerseTodayPrg> ret;
    if (config.learnCount <= 0) {
      ret = curr;
    } else {
      ret = curr.sublist(0, curr.length < config.learnCount ? curr.length : config.learnCount);
    }
    all.removeWhere((a) => ret.any((b) => a.verseId == b.verseId));

    for (int i = 0; i < ret.length; i++) {
      ret[i].progress = 0;
    }
    VerseTodayPrg.setType(ret, TodayPrgType.learn, index, config.learnCountPerGroup);
    return ret;
  }

  @transaction
  Future<void> addFullCustom(int bookId, int chapterIndex, int verseIndex, int limit) async {
    List<VerseTodayPrg> ret;
    ret = await scheduleFullCustom(Classroom.curr, bookId, chapterIndex, verseIndex, limit);
    String? fullCustomJsonStr = await stringKv(Classroom.curr, CrK.todayFullCustomScheduleConfigCount);
    List<List<String>> fullCustomConfigs = ListUtil.toListList(fullCustomJsonStr);
    var contentName = await getBookNameById(bookId);
    List<String> args = [];
    args.add(contentName ?? '-');
    args.add('${chapterIndex + 1}');
    args.add('${verseIndex + 1}');
    args.add('$limit');
    fullCustomConfigs.add(args);
    insertKv(CrKv(Classroom.curr, CrK.todayFullCustomScheduleConfigCount, convert.jsonEncode(fullCustomConfigs)));
    VerseTodayPrg.setType(ret, TodayPrgType.fullCustom, fullCustomConfigs.length - 1, 0);

    await insertVerseTodayPrg(ret);
  }

  // @transaction
  // Future<bool> tUpdateVerseContent(int verseId, String content) async {
  //   VerseKey? verseKey = await getVerseKeyById(verseId);
  //   if (verseKey == null) {
  //     Snackbar.showAndThrow(I18nKey.labelNotFoundVerse.trArgs([verseId.toString()]));
  //     return false;
  //   }
  //   dynamic contentM;
  //   try {
  //     contentM = convert.jsonDecode(content);
  //     content = convert.jsonEncode(contentM);
  //   } catch (e) {
  //     Snackbar.showAndThrow(e.toString());
  //     return false;
  //   }
  //
  //   if (verseKey.content == content) {
  //     return true;
  //   }
  //   String key;
  //   try {
  //     VerseContent verse = VerseContent.fromJson(contentM);
  //     key = getKey(verse.key, verse.answer);
  //   } catch (e) {
  //     Snackbar.showAndThrow(e.toString());
  //     return false;
  //   }
  //   if (key.isEmpty) {
  //     Snackbar.showAndThrow(I18nKey.labelVerseKeyCantBeEmpty.tr);
  //     return false;
  //   }
  //
  //   var otherVerseKey = await getVerseKeyByKey(verseKey.bookId, key);
  //   if (otherVerseKey != null && otherVerseKey.id != verseKey.id) {
  //     Snackbar.showAndThrow(I18nKey.labelVerseKeyDuplicated.trArgs([key]));
  //     return false;
  //   }
  //
  //   var now = DateTime.now();
  //   await updateVerseKeyAndContent(verseId, key, content, verseKey.contentVersion + 1);
  //   await db.verseContentVersionDao.insertOrFail(VerseContentVersion(
  //     classroomId: verseKey.classroomId,
  //     bookId: verseKey.bookId,
  //     chapterId: verseKey.chapterId,
  //     verseId: verseId,
  //     t: VerseVersionType.content,
  //     version: verseKey.contentVersion + 1,
  //     reason: VersionReason.editor,
  //     content: content,
  //     createTime: now,
  //   ));
  //   await insertKv(CrKv(Classroom.curr, CrK.updateVerseShowTime, now.millisecondsSinceEpoch.toString()));
  //   if (getVerseShow != null) {
  //     VerseShow? currVerseShow = getVerseShow!(verseId);
  //     if (currVerseShow != null) {
  //       currVerseShow.verseContent = content;
  //       for (var set in setVerseShowContent) {
  //         set(verseId);
  //       }
  //       currVerseShow.k = key;
  //       currVerseShow.verseContentVersion++;
  //     }
  //   }
  //   return true;
  // }

  /// adjust progress start

  Future<Date> getTodayLearnCreateDate(DateTime now) async {
    var todayLearnCreateDate = await intKv(Classroom.curr, CrK.todayScheduleCreateDate);
    todayLearnCreateDate ??= Date.from(now).value;
    return Date(todayLearnCreateDate);
  }

  int getPrgTypeInt(VerseTodayPrg verseTodayPrg) {
    return getPrgType(verseTodayPrg).index;
  }

  TodayPrgType getPrgType(VerseTodayPrg verseTodayPrg) {
    TodayPrgType prgType = TodayPrgType.none;
    if (verseTodayPrg.reviewCreateDate.value == 0) {
      prgType = TodayPrgType.learn;
    } else if (verseTodayPrg.reviewCreateDate.value == 1) {
      prgType = TodayPrgType.fullCustom;
    } else {
      prgType = TodayPrgType.review;
    }
    return prgType;
  }

  Future<void> setPrg(int verseId, int progress, Date? nextLearnDate) async {
    if (nextLearnDate != null) {
      await setPrgAndLearnDate4Sop(verseId, progress, nextLearnDate);
    } else {
      await setPrg4Sop(verseId, progress);
    }
    var now = DateTime.now();
    await insertKv(CrKv(Classroom.curr, CrK.updateVerseShowTime, now.millisecondsSinceEpoch.toString()));
    if (VerseDao.getVerseShow != null) {
      VerseShow? currVerseShow = VerseDao.getVerseShow!(verseId);
      if (currVerseShow != null) {
        currVerseShow.progress = progress;
        if (nextLearnDate != null) {
          currVerseShow.nextLearnDate = nextLearnDate;
        }
      }
    }
  }

  @transaction
  Future<void> error(VerseTodayPrg stp) async {
    await forUpdate();
    var now = DateTime.now();
    await setTodayPrgWithCache(stp, 0, now);
    await setPrg(stp.verseId, 0, null);
  }

  @transaction
  Future<void> jumpDirectly(int verseId, int progress, int nextDayValue) async {
    await forUpdate();
    await setPrg(verseId, progress, Date(nextDayValue));
  }

  @transaction
  Future<void> jump(VerseTodayPrg stp, int progress, int nextDayValue) async {
    await forUpdate();

    TodayPrgType prgType = getPrgType(stp);

    var now = DateTime.now();
    var todayLearnCreateDate = await getTodayLearnCreateDate(now);

    if (prgType == TodayPrgType.learn) {
      await insertVerseReview([
        VerseReview(
          createDate: todayLearnCreateDate,
          verseId: stp.verseId,
          classroomId: Classroom.curr,
          bookId: stp.bookId,
          chapterId: stp.chapterId,
          count: 0,
        )
      ]);
    } else if (prgType == TodayPrgType.review) {
      await setVerseReviewCount(stp.reviewCreateDate, stp.verseId, stp.reviewCount + 1);
    }

    await setPrg(stp.verseId, progress, Date(nextDayValue));
    await setTodayPrgWithCache(stp, scheduleConfig.maxRepeatTime, now);
    await insertVerseStats(VerseStats(
      verseId: stp.verseId,
      type: getPrgTypeInt(stp),
      createDate: todayLearnCreateDate,
      createTime: now.millisecondsSinceEpoch,
      classroomId: Classroom.curr,
      bookId: stp.bookId,
      chapterId: stp.chapterId,
    ));
  }

  @transaction
  Future<void> right(VerseTodayPrg stp) async {
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
          var verseProgress = await getVerseProgress(stp.verseId);
          if (verseProgress == null) {
            return;
          }
          nextProgress = verseProgress + 1;
        }
        await setPrg(stp.verseId, nextProgress, getNextByProgress(todayLearnCreateDate.toDateTime(), nextProgress));
        await insertVerseReview([
          VerseReview(
            createDate: todayLearnCreateDate,
            verseId: stp.verseId,
            classroomId: Classroom.curr,
            bookId: stp.bookId,
            chapterId: stp.chapterId,
            count: 0,
          )
        ]);
      } else if (prgType == TodayPrgType.review) {
        await setVerseReviewCount(stp.reviewCreateDate, stp.verseId, stp.reviewCount + 1);
      }
      await setTodayPrgWithCache(stp, scheduleConfig.maxRepeatTime, now);
      await insertVerseStats(VerseStats(
        verseId: stp.verseId,
        type: prgType.index,
        createDate: todayLearnCreateDate,
        createTime: now.millisecondsSinceEpoch,
        classroomId: Classroom.curr,
        bookId: stp.bookId,
        chapterId: stp.chapterId,
      ));
    }
  }

  Future<void> setTodayPrgWithCache(VerseTodayPrg verseTodayPrg, int progress, DateTime now) async {
    var finish = false;
    if (progress >= scheduleConfig.maxRepeatTime) {
      finish = true;
    }
    await setVerseTodayPrg(
      verseTodayPrg.verseId,
      verseTodayPrg.type,
      progress,
      now,
      finish,
    );
    verseTodayPrg.progress = progress;
    verseTodayPrg.viewTime = now;
    verseTodayPrg.finish = finish;
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
