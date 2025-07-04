// dao/schedule_dao.dart

import 'dart:convert' as convert;

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/verse.dart';
import 'package:repeat_flutter/db/entity/chapter.dart';
import 'package:repeat_flutter/db/entity/chapter_key.dart';
import 'package:repeat_flutter/db/entity/verse_content_version.dart';
import 'package:repeat_flutter/db/entity/verse_key.dart';
import 'package:repeat_flutter/db/entity/verse_overall_prg.dart';
import 'package:repeat_flutter/db/entity/verse_review.dart';
import 'package:repeat_flutter/db/entity/content_version.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/key_id.dart';
import 'package:repeat_flutter/logic/model/verse_overall_prg_with_key.dart';
import 'package:repeat_flutter/logic/model/verse_review_with_key.dart';
import 'package:repeat_flutter/db/entity/verse_stats.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
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

  static VerseShow? Function(int verseKeyId)? getVerseShow;
  static List<void Function(int verseKeyId)> setVerseShowContent = [];
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

  @Query('UPDATE Book set hide=true,docId=0'
      ' WHERE Book.id=:id')
  Future<void> hideBook(int id);

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

  @Query('UPDATE VerseTodayPrg SET progress=:progress,viewTime=:viewTime,finish=:finish WHERE verseKeyId=:verseKeyId and type=:type')
  Future<void> setVerseTodayPrg(int verseKeyId, int type, int progress, DateTime viewTime, bool finish);

  @Query("SELECT IFNULL(MIN(VerseReview.createDate),-1) FROM VerseReview"
      " JOIN Verse ON Verse.verseKeyId=VerseReview.verseKeyId"
      " WHERE VerseReview.classroomId=:classroomId"
      " AND VerseReview.count=:reviewCount"
      " and VerseReview.createDate<=:now"
      " order by VerseReview.createDate")
  Future<int?> findReviewedMinCreateDate(int classroomId, int reviewCount, Date now);

  @Query("SELECT"
      " VerseReview.classroomId"
      ",Verse.bookId"
      ",Chapter.chapterKeyId"
      ",VerseReview.verseKeyId"
      ",0 time"
      ",0 type"
      ",Verse.sort"
      ",0 progress"
      ",0 viewTime"
      ",VerseReview.count reviewCount"
      ",VerseReview.createDate reviewCreateDate"
      ",0 finish"
      " FROM VerseReview"
      " JOIN Verse ON Verse.verseKeyId=VerseReview.verseKeyId"
      " JOIN Chapter ON Chapter.bookId=Verse.bookId"
      "  AND Chapter.chapterIndex=Verse.chapterIndex"
      " WHERE VerseReview.classroomId=:classroomId"
      " AND VerseReview.count=:reviewCount"
      " AND VerseReview.createDate=:startDate"
      " ORDER BY Verse.sort")
  Future<List<VerseTodayPrg>> scheduleReview(int classroomId, int reviewCount, Date startDate);

  @Query("SELECT * FROM ("
      " SELECT"
      " Verse.classroomId"
      ",Verse.bookId"
      ",Chapter.chapterKeyId"
      ",VerseOverallPrg.verseKeyId"
      ",0 time"
      ",0 type"
      ",Verse.sort"
      ",VerseOverallPrg.progress progress"
      ",0 viewTime"
      ",0 reviewCount"
      ",0 reviewCreateDate"
      ",0 finish"
      " FROM VerseOverallPrg"
      " JOIN Verse ON Verse.verseKeyId=VerseOverallPrg.verseKeyId"
      "  AND Verse.classroomId=:classroomId"
      " JOIN Chapter ON Chapter.bookId=Verse.bookId"
      "  AND Chapter.chapterIndex=Verse.chapterIndex"
      " WHERE VerseOverallPrg.next<=:now"
      "  AND VerseOverallPrg.progress>=:minProgress"
      " ORDER BY VerseOverallPrg.progress,Verse.sort"
      " ) Verse order by Verse.sort")
  Future<List<VerseTodayPrg>> scheduleLearn(int classroomId, int minProgress, Date now);

  @Query("SELECT"
      " Verse.classroomId"
      ",Verse.bookId"
      ",Chapter.chapterKeyId"
      ",Verse.verseKeyId"
      ",0 time"
      ",0 type"
      ",Verse.sort"
      ",0 progress"
      ",0 viewTime"
      ",0 reviewCount"
      ",1 reviewCreateDate"
      ",0 finish"
      " FROM Verse"
      " JOIN Chapter ON Chapter.bookId=Verse.bookId"
      "  AND Chapter.chapterIndex=Verse.chapterIndex"
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

  @Query('UPDATE VerseOverallPrg SET progress=:progress,next=:next WHERE verseKeyId=:verseKeyId')
  Future<void> setPrgAndNext4Sop(int verseKeyId, int progress, Date next);

  @Query('UPDATE VerseOverallPrg SET progress=:progress WHERE verseKeyId=:verseKeyId')
  Future<void> setPrg4Sop(int verseKeyId, int progress);

  @Query("SELECT progress FROM VerseOverallPrg WHERE verseKeyId=:verseKeyId")
  Future<int?> getVerseProgress(int verseKeyId);

  @Query("SELECT VerseOverallPrg.*"
      ",Book.name contentName"
      ",Verse.chapterIndex"
      ",Verse.verseIndex"
      " FROM Verse"
      " JOIN VerseOverallPrg on VerseOverallPrg.verseKeyId=Verse.verseKeyId"
      " JOIN Book ON Book.id=Verse.bookId"
      " WHERE Verse.classroomId=:classroomId"
      " ORDER BY Verse.sort asc")
  Future<List<VerseOverallPrgWithKey>> getAllVerseOverallPrg(int classroomId);

  /// --- VerseReview
  @Query("SELECT Book.name FROM Book WHERE Book.id=:bookId")
  Future<String?> getBookNameById(int bookId);

  @Query("SELECT VerseReview.*"
      ",Book.name contentName"
      ",Verse.chapterIndex"
      ",Verse.verseIndex"
      " FROM VerseReview"
      " JOIN Verse ON Verse.verseKeyId=VerseReview.verseKeyId"
      " JOIN Book ON Book.id=VerseReview.bookId"
      " WHERE VerseReview.classroomId=:classroomId"
      " AND VerseReview.createDate>=:start AND VerseReview.createDate<=:end"
      " ORDER BY VerseReview.createDate desc,Verse.sort asc")
  Future<List<VerseReviewWithKey>> getAllVerseReview(int classroomId, Date start, Date end);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertVerseReview(List<VerseReview> review);

  @Query('UPDATE VerseReview SET count=:count WHERE createDate=:createDate and `verseKeyId`=:verseKeyId')
  Future<void> setVerseReviewCount(Date createDate, int verseKeyId, int count);

  @Query("SELECT"
      " Book.name contentName"
      " FROM VerseKey"
      " JOIN Book ON Book.id=VerseKey.bookId"
      " WHERE VerseKey.id=:verseKeyId")
  Future<String?> getBookName(int verseKeyId);

  @Query("SELECT LimitVerse.verseKeyId"
      " FROM (SELECT sort,verseKeyId"
      "  FROM Verse"
      "  WHERE classroomId=:classroomId"
      "  AND sort<(SELECT Verse.sort FROM Verse WHERE Verse.verseKeyId=:verseKeyId)"
      "  ORDER BY sort desc"
      "  LIMIT :offset) LimitVerse"
      "  ORDER BY LimitVerse.sort"
      " LIMIT 1")
  Future<int?> getPrevVerseKeyIdWithOffset(int classroomId, int verseKeyId, int offset);

  @Query("SELECT LimitVerse.verseKeyId"
      " FROM (SELECT sort,verseKeyId"
      "  FROM Verse"
      "  WHERE classroomId=:classroomId"
      "  AND sort>(SELECT Verse.sort FROM Verse WHERE Verse.verseKeyId=:verseKeyId)"
      "  ORDER BY sort"
      "  LIMIT :offset) LimitVerse"
      "  ORDER BY LimitVerse.sort desc"
      " LIMIT 1")
  Future<int?> getNextVerseKeyIdWithOffset(int classroomId, int verseKeyId, int offset);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertVerseKeys(List<VerseKey> entities);

  @Update()
  Future<void> updateVerseKeys(List<VerseKey> entities);

  @Query('SELECT VerseKey.id'
      ',VerseKey.k FROM VerseKey'
      ' WHERE VerseKey.bookId=:bookId')
  Future<List<KeyId>> getVerseKeyId(int bookId);

  @Query('SELECT VerseKey.* FROM VerseKey'
      ' WHERE VerseKey.bookId=:bookId')
  Future<List<VerseKey>> getVerseKey(int bookId);

  @Query('SELECT VerseKey.* FROM VerseKey'
      ' WHERE VerseKey.id=:id')
  Future<VerseKey?> getVerseKeyById(int id);

  @Query('SELECT VerseKey.* FROM VerseKey'
      ' WHERE VerseKey.bookId=:bookId'
      ' AND VerseKey.k=:key')
  Future<VerseKey?> getVerseKeyByKey(int bookId, String key);

  @Query('SELECT VerseKey.id verseKeyId'
      ',VerseKey.k'
      ',Book.id bookId'
      ',Book.name bookName'
      ',Book.sort bookSort'
      ',VerseKey.content verseContent'
      ',VerseKey.contentVersion verseContentVersion'
      ',VerseKey.note verseNote'
      ',VerseKey.noteVersion verseNoteVersion'
      ',VerseKey.chapterKeyId'
      ',VerseKey.chapterIndex'
      ',VerseKey.verseIndex'
      ',VerseOverallPrg.next'
      ',VerseOverallPrg.progress'
      ',Verse.verseKeyId is null missing'
      ' FROM VerseKey'
      ' JOIN Book ON Book.id=VerseKey.bookId AND Book.docId!=0'
      ' LEFT JOIN Verse ON Verse.verseKeyId=VerseKey.id'
      ' LEFT JOIN VerseOverallPrg ON VerseOverallPrg.verseKeyId=VerseKey.id'
      ' WHERE VerseKey.classroomId=:classroomId')
  Future<List<VerseShow>> getAllVerse(int classroomId);

  @Query('SELECT VerseKey.id verseKeyId'
      ',VerseKey.k'
      ',Book.id bookId'
      ',Book.name bookName'
      ',Book.sort bookSort'
      ',VerseKey.content verseContent'
      ',VerseKey.contentVersion verseContentVersion'
      ',VerseKey.note verseNote'
      ',VerseKey.noteVersion verseNoteVersion'
      ',VerseKey.chapterKeyId'
      ',VerseKey.chapterIndex'
      ',VerseKey.verseIndex'
      ',VerseOverallPrg.next'
      ',VerseOverallPrg.progress'
      ',Verse.verseKeyId is null missing'
      ' FROM VerseKey'
      " JOIN Book ON Book.id=:bookId AND Book.docId!=0"
      ' LEFT JOIN Verse ON Verse.verseKeyId=VerseKey.id'
      ' LEFT JOIN VerseOverallPrg ON VerseOverallPrg.verseKeyId=VerseKey.id'
      ' WHERE VerseKey.bookId=:bookId'
      '  AND VerseKey.chapterIndex=:chapterIndex')
  Future<List<VerseShow>> getVerseByChapterIndex(int bookId, int chapterIndex);

  @Query('SELECT VerseKey.id verseKeyId'
      ',VerseKey.k'
      ',Book.id bookId'
      ',Book.name bookName'
      ',Book.sort bookSort'
      ',VerseKey.content verseContent'
      ',VerseKey.contentVersion verseContentVersion'
      ',VerseKey.note verseNote'
      ',VerseKey.noteVersion verseNoteVersion'
      ',VerseKey.chapterKeyId'
      ',VerseKey.chapterIndex'
      ',VerseKey.verseIndex'
      ',VerseOverallPrg.next'
      ',VerseOverallPrg.progress'
      ',Verse.verseKeyId is null missing'
      ' FROM VerseKey'
      " JOIN Book ON Book.id=VerseKey.bookId AND Book.docId!=0"
      ' LEFT JOIN Verse ON Verse.verseKeyId=VerseKey.id'
      ' LEFT JOIN VerseOverallPrg ON VerseOverallPrg.verseKeyId=VerseKey.id'
      ' WHERE VerseKey.bookId=:bookId'
      '  AND VerseKey.chapterIndex>=:minChapterIndex')
  Future<List<VerseShow>> getVerseByMinChapterIndex(int bookId, int minChapterIndex);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertVerses(List<Verse> entities);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertVerseOverallPrgs(List<VerseOverallPrg> entities);

  @Query('DELETE FROM Verse WHERE verseKeyId=:verseKeyId')
  Future<void> deleteVerse(int verseKeyId);

  @Query('DELETE FROM VerseKey WHERE id=:verseKeyId')
  Future<void> deleteVerseKey(int verseKeyId);

  @Query('DELETE FROM VerseOverallPrg WHERE verseKeyId=:verseKeyId')
  Future<void> deleteVerseOverallPrg(int verseKeyId);

  @Query('DELETE FROM VerseReview WHERE verseKeyId=:verseKeyId')
  Future<void> deleteVerseReview(int verseKeyId);

  @Query('DELETE FROM VerseTodayPrg WHERE verseKeyId=:verseKeyId')
  Future<void> deleteVerseTodayPrg(int verseKeyId);

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

  @transaction
  Future<void> deleteAbnormalVerse(int verseKeyId) async {
    await forUpdate();
    await deleteVerse(verseKeyId);
    await deleteVerseKey(verseKeyId);
    await deleteVerseOverallPrg(verseKeyId);
    await deleteVerseReview(verseKeyId);
    await deleteVerseTodayPrg(verseKeyId);
    await db.verseContentVersionDao.deleteByVerseKeyId(verseKeyId);
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

  Future<Book?> prepareImportVerse({
    required List<Chapter> chapters,
    required List<ChapterKey> chapterKeys,
    required List<VerseKey> verseKeys,
    required List<Verse> verses,
    required List<VerseOverallPrg> verseOverallPrgs,
    required int bookId,
    String? url,
  }) async {
    Book? book = await db.bookDao.getById(bookId);
    if (book == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["book"]));
      return null;
    }
    Map<String, dynamic>? jsonData = await DocHelp.toJsonMap(DocPath.getRelativeIndexPath(book.id!));
    if (jsonData == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["jsonData"]));
      return null;
    }
    var kv = BookContent.fromJson(jsonData);
    if (kv.chapter.length >= 100000) {
      Snackbar.showAndThrow(I18nKey.labelTooMuchData.trArgs(["chapter"]));
      return null;
    }
    for (var d in kv.chapter) {
      if (d.verse.length >= 100000) {
        Snackbar.showAndThrow(I18nKey.labelTooMuchData.trArgs(["verse"]));
        return null;
      }
    }
    Map<String, bool> verseKey = {};
    var now = DateTime.now();

    Map<String, dynamic> excludeChapter = {};
    jsonData.forEach((k, v) {
      if (k != 'c') {
        excludeChapter[k] = v;
      }
    });
    book.content = convert.jsonEncode(excludeChapter);

    List<dynamic> rawChapters = jsonData['c'] as List<dynamic>;
    for (var chapterIndex = 0; chapterIndex < kv.chapter.length; chapterIndex++) {
      Map<String, dynamic> rawChapter = rawChapters[chapterIndex] as Map<String, dynamic>;
      Map<String, dynamic> excludeVerse = {};
      rawChapter.forEach((k, v) {
        if (k != 'v') {
          excludeVerse[k] = v;
        }
      });
      String chapterContent = convert.jsonEncode(excludeVerse);

      var chapter = kv.chapter[chapterIndex];
      chapters.add(Chapter(
        classroomId: book.classroomId,
        bookId: book.id!,
        chapterIndex: chapterIndex,
      ));
      chapterKeys.add(ChapterKey(
        classroomId: book.classroomId,
        bookId: book.id!,
        chapterIndex: chapterIndex,
        version: 1,
        content: chapterContent,
        contentVersion: 1,
      ));
      List<dynamic> rawVerses = rawChapter['v'] as List<dynamic>;
      for (var verseIndex = 0; verseIndex < chapter.verse.length; verseIndex++) {
        var rawVerse = rawVerses[verseIndex] as Map<String, dynamic>;
        var verse = chapter.verse[verseIndex];
        if (verse.answer.isEmpty) {
          Snackbar.showAndThrow(I18nKey.labelVerseNeedToContainAnswer.tr);
          return null;
        }
        var key = getKey(verse.key, verse.answer);
        if (verseKey.containsKey(key)) {
          Snackbar.showAndThrow(I18nKey.labelVerseKeyDuplicated.trArgs([key]));
          return null;
        }
        verseKey[key] = true;
        Map<String, dynamic> excludeNote = {};
        rawVerse.forEach((k, v) {
          if (k != 'n') {
            excludeNote[k] = v;
          }
        });
        String verseContent = convert.jsonEncode(excludeNote);
        verseKeys.add(VerseKey(
          classroomId: book.classroomId,
          bookId: book.id!,
          chapterKeyId: 0,
          chapterIndex: chapterIndex,
          verseIndex: verseIndex,
          version: 1,
          k: key,
          content: verseContent,
          contentVersion: 1,
          note: verse.note ?? '',
          noteVersion: 1,
        ));
        verses.add(Verse(
          verseKeyId: 0,
          classroomId: book.classroomId,
          bookId: book.id!,
          chapterKeyId: 0,
          chapterIndex: chapterIndex,
          verseIndex: verseIndex,
          //4611686118427387904-(99999*10000000000+99999*100000+99999)
          sort: book.sort * 10000000000 + chapterIndex * 100000 + verseIndex,
        ));
        verseOverallPrgs.add(VerseOverallPrg(
          verseKeyId: 0,
          classroomId: book.classroomId,
          bookId: book.id!,
          chapterKeyId: 0,
          next: Date.from(now),
          progress: 0,
        ));
      }
    }
    return book;
  }

  @transaction
  Future<int> importVerse(
    int bookId,
    String? url,
  ) async {
    await forUpdate();
    List<Chapter> chapters = [];
    List<ChapterKey> chapterKeys = [];
    List<VerseKey> verseKeys = [];
    List<Verse> verses = [];
    List<VerseOverallPrg> verseOverallPrgs = [];
    Book? book = await prepareImportVerse(
      chapters: chapters,
      chapterKeys: chapterKeys,
      verseKeys: verseKeys,
      verses: verses,
      verseOverallPrgs: verseOverallPrgs,
      bookId: bookId,
      url: url,
    );
    if (book == null) {
      return ImportResult.error.index;
    }

    List<VerseKey> oldVerseKeys = await getVerseKey(bookId);
    var maxVersion = 0;
    Map<String, VerseKey> keyToOldVerseKey = {};
    Map<String, int> keyToId = {};
    List<int> oldVerseKeyIds = [];
    for (var oldVerseKey in oldVerseKeys) {
      if (oldVerseKey.version > maxVersion) {
        maxVersion = oldVerseKey.version;
      }
      keyToOldVerseKey[oldVerseKey.k] = oldVerseKey;
      keyToId[oldVerseKey.k] = oldVerseKey.id!;
      oldVerseKeyIds.add(oldVerseKey.id!);
    }
    var nextVersion = maxVersion + 1;
    Map<int, VerseKey> needToModifyMap = {};
    List<VerseKey> needToInsert = [];
    var warningInChapter = await db.chapterKeyDao.import(chapters, chapterKeys, book.id!);
    for (var newVerseKey in verseKeys) {
      newVerseKey.version = nextVersion;
      newVerseKey.chapterKeyId = chapterKeys[newVerseKey.chapterIndex].id!;
      VerseKey? oldVerseKey = keyToOldVerseKey[newVerseKey.k];
      if (oldVerseKey == null) {
        needToInsert.add(newVerseKey);
      } else {
        newVerseKey.id = oldVerseKey.id;
        newVerseKey.contentVersion = oldVerseKey.contentVersion;
        newVerseKey.noteVersion = oldVerseKey.noteVersion;
        if (oldVerseKey.chapterKeyId != newVerseKey.chapterKeyId || //
            oldVerseKey.chapterIndex != newVerseKey.chapterIndex || //
            oldVerseKey.verseIndex != newVerseKey.verseIndex || //
            oldVerseKey.content != newVerseKey.content || //
            oldVerseKey.note != newVerseKey.note) {
          needToModifyMap[oldVerseKey.id!] = newVerseKey;
        }
      }
    }
    if (needToInsert.isNotEmpty) {
      await insertVerseKeys(needToInsert);
      var keyIds = await getVerseKeyId(bookId);
      keyToId = {for (var keyId in keyIds) keyId.k: keyId.id};
      for (var newVerseKey in verseKeys) {
        int? id = keyToId[newVerseKey.k];
        if (id != null) {
          newVerseKey.id = id;
        }
      }
    }

    Map<int, VerseContentVersion> newVerseKeyIdToContentVersion = await db.verseContentVersionDao.import(verseKeys, VerseVersionType.content, book.id!);
    Map<int, VerseContentVersion> newVerseKeyIdToNoteVersion = await db.verseContentVersionDao.import(verseKeys, VerseVersionType.note, book.id!);
    for (var i = 0; i < verseKeys.length; i++) {
      VerseKey newVerseKey = verseKeys[i];
      var id = keyToId[newVerseKey.k]!;
      var contentVersion = newVerseKeyIdToContentVersion[id];
      if (contentVersion != null && newVerseKey.contentVersion != contentVersion.version) {
        newVerseKey.contentVersion = contentVersion.version;
        needToModifyMap[newVerseKey.id!] = newVerseKey;
      }
      var noteVersion = newVerseKeyIdToNoteVersion[id];
      if (noteVersion != null && newVerseKey.noteVersion != noteVersion.version) {
        newVerseKey.noteVersion = noteVersion.version;
        needToModifyMap[newVerseKey.id!] = newVerseKey;
      }
      verses[i].verseKeyId = id;
      verses[i].chapterKeyId = newVerseKey.chapterKeyId;
      verseOverallPrgs[i].verseKeyId = id;
      verseOverallPrgs[i].chapterKeyId = newVerseKey.chapterKeyId;
    }
    await db.verseDao.deleteByBookId(bookId);
    await insertVerses(verses);
    await insertVerseOverallPrgs(verseOverallPrgs);
    if (needToModifyMap.isNotEmpty) {
      await updateVerseKeys(needToModifyMap.values.toList());
    }
    await db.bookDao.import(bookId, book.content);

    var warningInVerse = verses.length < keyToId.length;

    if (url != null) {
      await db.bookDao.updateBook(bookId, 1, url, warningInChapter, warningInVerse, DateTime.now().millisecondsSinceEpoch);
    } else {
      await db.bookDao.updateBookWarning(bookId, warningInChapter, warningInVerse, DateTime.now().millisecondsSinceEpoch);
    }
    if (warningInChapter == true || warningInVerse == true) {
      return ImportResult.successButSomeVersesAreSurplus.index;
    } else {
      return ImportResult.success.index;
    }
  }

  @transaction
  Future<bool> deleteNormalVerse(int verseKeyId) async {
    await forUpdate();
    var raw = await db.verseKeyDao.oneById(verseKeyId);
    if (raw == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["cant find the data($verseKeyId)"]));
      return false;
    }
    int verseIndex = raw.verseIndex;
    var verses = await db.verseDao.findByMinVerseIndex(raw.bookId, raw.chapterIndex, verseIndex);
    var verseKeys = await db.verseKeyDao.findByMinVerseIndex(raw.bookId, raw.chapterIndex, verseIndex);
    List<Verse> insertVerses = [];
    List<VerseKey> insertVerseKeys = [];
    for (var v in verses) {
      v.verseIndex--;
      v.sort--;
      if (v.verseKeyId != verseKeyId) {
        insertVerses.add(v);
      }
    }
    for (var v in verseKeys) {
      v.verseIndex--;
      if (v.id != verseKeyId) {
        insertVerseKeys.add(v);
      }
    }
    await db.verseDao.deleteByMinVerseIndex(raw.bookId, raw.chapterIndex, verseIndex);
    await db.verseKeyDao.deleteByMinVerseIndex(raw.bookId, raw.chapterIndex, verseIndex);
    await db.verseDao.insertListOrFail(insertVerses);
    await db.verseKeyDao.insertListOrFail(insertVerseKeys);
    await deleteVerseOverallPrg(verseKeyId);
    await deleteVerseReview(verseKeyId);
    await deleteVerseTodayPrg(verseKeyId);
    await db.verseContentVersionDao.deleteByVerseKeyId(verseKeyId);
    return true;
  }

  @transaction
  Future<int> addVerse(VerseShow raw, int verseIndex) async {
    return interAddVerse(
      verseContent: raw.verseContent,
      bookId: raw.bookId,
      chapterKeyId: raw.chapterKeyId,
      chapterIndex: raw.chapterIndex,
      verseIndex: verseIndex,
    );
  }

  @transaction
  Future<int> addFirstVerse(
    int bookId,
    int chapterKeyId,
    int chapterIndex,
  ) async {
    return interAddVerse(
      verseContent: "{}",
      bookId: bookId,
      chapterKeyId: chapterKeyId,
      chapterIndex: chapterIndex,
      verseIndex: 0,
    );
  }

  Future<int> interAddVerse({
    required String verseContent,
    required int bookId,
    required int chapterKeyId,
    required int chapterIndex,
    required int verseIndex,
  }) async {
    Book? book = await db.bookDao.getById(bookId);
    if (book == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["book"]));
      return 0;
    }
    String content = "";
    String key = "";
    Map<String, dynamic> contentMap;
    try {
      contentMap = convert.jsonDecode(verseContent);
      if (contentMap['k'] == null || contentMap['k'].toString().isEmpty) {
        if (contentMap['a'] != null && contentMap['a'].toString().isNotEmpty) {
          contentMap['k'] = '${contentMap['a']}_${DateTime.now().millisecondsSinceEpoch}';
        } else {
          contentMap['a'] = 'verse_${DateTime.now().millisecondsSinceEpoch}';
        }
      } else {
        contentMap['k'] = '${contentMap['k']}_${DateTime.now().millisecondsSinceEpoch}';
      }
      content = convert.jsonEncode(contentMap);

      if (contentMap['k'] != null) {
        key = contentMap['k'].toString();
      } else {
        key = contentMap['a'].toString();
      }
    } catch (e) {
      return 0;
    }
    int classroomId = Classroom.curr;
    var existingVerse = await getVerseKeyByKey(bookId, key);
    if (existingVerse != null) {
      Snackbar.showAndThrow(I18nKey.labelVerseKeyDuplicated.trArgs([key]));
      return 0;
    }

    // adjust the verse index and sort
    var verses = await db.verseDao.findByMinVerseIndex(bookId, chapterIndex, verseIndex);
    var verseKeys = await db.verseKeyDao.findByMinVerseIndex(bookId, chapterIndex, verseIndex);
    for (var v in verses) {
      v.verseIndex++;
      v.sort++;
    }
    for (var v in verseKeys) {
      v.verseIndex++;
    }
    await db.verseDao.deleteByMinVerseIndex(bookId, chapterIndex, verseIndex);
    await db.verseKeyDao.deleteByMinVerseIndex(bookId, chapterIndex, verseIndex);

    // insert and get the verse key id
    VerseKey? verseKey = VerseKey(
      classroomId: classroomId,
      bookId: bookId,
      chapterKeyId: chapterKeyId,
      chapterIndex: chapterIndex,
      verseIndex: verseIndex,
      version: 1,
      k: key,
      content: content,
      contentVersion: 1,
      note: '',
      noteVersion: 1,
    );
    verseKeys.add(verseKey);
    await db.verseKeyDao.insertListOrFail(verseKeys);
    verseKey = await getVerseKeyByKey(verseKey.bookId, key);
    if (verseKey == null) {
      throw Exception('Failed to get verse key');
    }

    int sortValue = book.sort * 10000000000 + verseKey.chapterIndex * 100000 + verseIndex;
    var verse = Verse(
      verseKeyId: verseKey.id!,
      classroomId: verseKey.classroomId,
      bookId: verseKey.bookId,
      chapterKeyId: verseKey.chapterKeyId,
      chapterIndex: verseKey.chapterIndex,
      verseIndex: verseKey.verseIndex,
      sort: sortValue,
    );
    verses.add(verse);
    await db.verseDao.insertListOrFail(verses);
    var now = DateTime.now();
    var verseOverallPrg = VerseOverallPrg(
      verseKeyId: verseKey.id!,
      classroomId: verseKey.classroomId,
      bookId: verseKey.bookId,
      chapterKeyId: verseKey.chapterKeyId,
      next: Date.from(now),
      progress: 0,
    );
    await db.verseOverallPrgDao.insertOrFail(verseOverallPrg);
    await db.verseContentVersionDao.insertOrFail(VerseContentVersion(
      classroomId: verseKey.classroomId,
      bookId: verseKey.bookId,
      chapterKeyId: verseKey.chapterKeyId,
      verseKeyId: verseKey.id!,
      t: VerseVersionType.content,
      version: 1,
      reason: VersionReason.editor,
      content: verseKey.content,
      createTime: now,
    ));
    await db.verseContentVersionDao.insertOrFail(VerseContentVersion(
      classroomId: verseKey.classroomId,
      bookId: verseKey.bookId,
      chapterKeyId: verseKey.chapterKeyId,
      verseKeyId: verseKey.id!,
      t: VerseVersionType.note,
      version: 1,
      reason: VersionReason.editor,
      content: verseKey.note,
      createTime: now,
    ));

    await insertKv(CrKv(verseKey.classroomId, CrK.updateVerseShowTime, now.millisecondsSinceEpoch.toString()));

    return verseKey.id!;
  }

  @transaction
  Future<void> hideContentAndDeleteVerse(int bookId) async {
    await forUpdate();
    await hideBook(bookId);
    await db.verseDao.deleteByBookId(bookId);
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
    all.removeWhere((a) => ret.any((b) => a.verseKeyId == b.verseKeyId));

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

  @transaction
  Future<bool> tUpdateVerseContent(int verseKeyId, String content) async {
    VerseKey? verseKey = await getVerseKeyById(verseKeyId);
    if (verseKey == null) {
      Snackbar.showAndThrow(I18nKey.labelNotFoundVerse.trArgs([verseKeyId.toString()]));
      return false;
    }
    dynamic contentM;
    try {
      contentM = convert.jsonDecode(content);
      content = convert.jsonEncode(contentM);
    } catch (e) {
      Snackbar.showAndThrow(e.toString());
      return false;
    }

    if (verseKey.content == content) {
      return true;
    }
    String key;
    try {
      VerseContent verse = VerseContent.fromJson(contentM);
      key = getKey(verse.key, verse.answer);
    } catch (e) {
      Snackbar.showAndThrow(e.toString());
      return false;
    }
    if (key.isEmpty) {
      Snackbar.showAndThrow(I18nKey.labelVerseKeyCantBeEmpty.tr);
      return false;
    }

    var otherVerseKey = await getVerseKeyByKey(verseKey.bookId, key);
    if (otherVerseKey != null && otherVerseKey.id != verseKey.id) {
      Snackbar.showAndThrow(I18nKey.labelVerseKeyDuplicated.trArgs([key]));
      return false;
    }

    var now = DateTime.now();
    await updateVerseKeyAndContent(verseKeyId, key, content, verseKey.contentVersion + 1);
    await db.verseContentVersionDao.insertOrFail(VerseContentVersion(
      classroomId: verseKey.classroomId,
      bookId: verseKey.bookId,
      chapterKeyId: verseKey.chapterKeyId,
      verseKeyId: verseKeyId,
      t: VerseVersionType.content,
      version: verseKey.contentVersion + 1,
      reason: VersionReason.editor,
      content: content,
      createTime: now,
    ));
    await insertKv(CrKv(Classroom.curr, CrK.updateVerseShowTime, now.millisecondsSinceEpoch.toString()));
    if (getVerseShow != null) {
      VerseShow? currVerseShow = getVerseShow!(verseKeyId);
      if (currVerseShow != null) {
        currVerseShow.verseContent = content;
        for (var set in setVerseShowContent) {
          set(verseKeyId);
        }
        currVerseShow.k = key;
        currVerseShow.verseContentVersion++;
      }
    }
    return true;
  }

  @transaction
  Future<void> tUpdateVerseNote(int verseKeyId, String note) async {
    VerseKey? verseKey = await getVerseKeyById(verseKeyId);
    if (verseKey == null) {
      Snackbar.showAndThrow(I18nKey.labelNotFoundVerse.trArgs([verseKeyId.toString()]));
      return;
    }
    if (verseKey.note == note) {
      return;
    }
    var now = DateTime.now();
    await updateVerseNote(verseKeyId, note, verseKey.noteVersion + 1);
    await db.verseContentVersionDao.insertOrFail(VerseContentVersion(
      classroomId: verseKey.classroomId,
      bookId: verseKey.bookId,
      chapterKeyId: verseKey.chapterKeyId,
      verseKeyId: verseKeyId,
      t: VerseVersionType.note,
      version: verseKey.noteVersion + 1,
      reason: VersionReason.editor,
      content: note,
      createTime: now,
    ));
    await insertKv(CrKv(Classroom.curr, CrK.updateVerseShowTime, now.millisecondsSinceEpoch.toString()));
    if (getVerseShow != null) {
      VerseShow? currVerseShow = getVerseShow!(verseKeyId);
      if (currVerseShow != null) {
        currVerseShow.verseNote = note;
        currVerseShow.verseNoteVersion++;
      }
    }
  }

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

  Future<void> setPrg(int verseKeyId, int progress, Date? next) async {
    if (next != null) {
      await setPrgAndNext4Sop(verseKeyId, progress, next);
    } else {
      await setPrg4Sop(verseKeyId, progress);
    }
    var now = DateTime.now();
    await insertKv(CrKv(Classroom.curr, CrK.updateVerseShowTime, now.millisecondsSinceEpoch.toString()));
    if (getVerseShow != null) {
      VerseShow? currVerseShow = getVerseShow!(verseKeyId);
      if (currVerseShow != null) {
        currVerseShow.progress = progress;
        if (next != null) {
          currVerseShow.next = next;
        }
      }
    }
  }

  @transaction
  Future<void> error(VerseTodayPrg stp) async {
    await forUpdate();
    var now = DateTime.now();
    await setTodayPrgWithCache(stp, 0, now);
    await setPrg(stp.verseKeyId, 0, null);
  }

  @transaction
  Future<void> jumpDirectly(int verseKeyId, int progress, int nextDayValue) async {
    await forUpdate();
    await setPrg(verseKeyId, progress, Date(nextDayValue));
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
          verseKeyId: stp.verseKeyId,
          classroomId: Classroom.curr,
          bookId: stp.bookId,
          chapterKeyId: stp.chapterKeyId,
          count: 0,
        )
      ]);
    } else if (prgType == TodayPrgType.review) {
      await setVerseReviewCount(stp.reviewCreateDate, stp.verseKeyId, stp.reviewCount + 1);
    }

    await setPrg(stp.verseKeyId, progress, Date(nextDayValue));
    await setTodayPrgWithCache(stp, scheduleConfig.maxRepeatTime, now);
    await insertVerseStats(VerseStats(
      verseKeyId: stp.verseKeyId,
      type: getPrgTypeInt(stp),
      createDate: todayLearnCreateDate,
      createTime: now.millisecondsSinceEpoch,
      classroomId: Classroom.curr,
      bookId: stp.bookId,
      chapterKeyId: stp.chapterKeyId,
    ));
  }

  @transaction
  Future<void> right(VerseTodayPrg stp) async {
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
          var verseProgress = await getVerseProgress(stp.verseKeyId);
          if (verseProgress == null) {
            return;
          }
          nextProgress = verseProgress + 1;
        }
        await setPrg(stp.verseKeyId, nextProgress, getNextByProgress(todayLearnCreateDate.toDateTime(), nextProgress));
        await insertVerseReview([
          VerseReview(
            createDate: todayLearnCreateDate,
            verseKeyId: stp.verseKeyId,
            classroomId: Classroom.curr,
            bookId: stp.bookId,
            chapterKeyId: stp.chapterKeyId,
            count: 0,
          )
        ]);
      } else if (prgType == TodayPrgType.review) {
        await setVerseReviewCount(stp.reviewCreateDate, stp.verseKeyId, stp.reviewCount + 1);
      }
      await setTodayPrgWithCache(stp, scheduleConfig.maxRepeatTime, now);
      await insertVerseStats(VerseStats(
        verseKeyId: stp.verseKeyId,
        type: prgType.index,
        createDate: todayLearnCreateDate,
        createTime: now.millisecondsSinceEpoch,
        classroomId: Classroom.curr,
        bookId: stp.bookId,
        chapterKeyId: stp.chapterKeyId,
      ));
    }
  }

  Future<void> setTodayPrgWithCache(VerseTodayPrg verseTodayPrg, int progress, DateTime now) async {
    var finish = false;
    if (progress >= scheduleConfig.maxRepeatTime) {
      finish = true;
    }
    await setVerseTodayPrg(
      verseTodayPrg.verseKeyId,
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
