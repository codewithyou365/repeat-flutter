// database.dart

// required package imports
import 'dart:async';
import 'dart:developer';
import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/dao/book_content_version_dao.dart';
import 'package:repeat_flutter/db/dao/chapter_content_version_dao.dart';
import 'package:repeat_flutter/db/dao/classroom_dao.dart';
import 'package:repeat_flutter/db/dao/book_dao.dart';
import 'package:repeat_flutter/db/dao/cr_kv_dao.dart';
import 'package:repeat_flutter/db/dao/game_dao.dart';
import 'package:repeat_flutter/db/dao/game_user_dao.dart';
import 'package:repeat_flutter/db/dao/chapter_dao.dart';
import 'package:repeat_flutter/db/dao/game_user_input_dao.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/dao/kv_dao.dart';
import 'package:repeat_flutter/db/dao/verse_content_version_dao.dart';
import 'package:repeat_flutter/db/dao/verse_dao.dart';
import 'package:repeat_flutter/db/dao/stats_dao.dart';
import 'package:repeat_flutter/db/dao/time_stats_dao.dart';
import 'package:repeat_flutter/db/dao/lock_dao.dart';
import 'package:repeat_flutter/db/dao/verse_review_dao.dart';
import 'package:repeat_flutter/db/dao/verse_stats_dao.dart';
import 'package:repeat_flutter/db/dao/verse_today_prg_dao.dart';
import 'package:repeat_flutter/db/entity/book_content_version.dart';
import 'package:repeat_flutter/db/entity/chapter_content_version.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/lock.dart';
import 'package:repeat_flutter/db/entity/chapter.dart';
import 'package:repeat_flutter/db/entity/verse.dart';
import 'package:repeat_flutter/db/entity/verse_content_version.dart';
import 'package:repeat_flutter/db/entity/verse_review.dart';
import 'package:repeat_flutter/db/entity/verse_stats.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/db/entity/game.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/game_user_input.dart';
import 'package:repeat_flutter/db/entity/time_stats.dart';
import 'package:repeat_flutter/db/migration/m1_2.dart';
import 'package:repeat_flutter/db/migration/m2_3.dart';
import 'package:repeat_flutter/db/type_converter.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';
import 'package:repeat_flutter/logic/model/key_id.dart';
import 'package:repeat_flutter/logic/model/verse_review_with_key.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'entity/kv.dart';

part 'database.g.dart'; // the generated code will be there

@Database(version: 3, entities: [
  Book,
  BookContentVersion,
  Chapter,
  ChapterContentVersion,
  Kv,
  Classroom,
  CrKv,
  Verse,
  VerseContentVersion,
  KeyId,
  VerseShow,
  VerseReview,
  VerseReviewWithKey,
  VerseTodayPrg,
  VerseStats,
  TimeStats,
  BookShow,
  Game,
  GameUser,
  GameUserInput,
  Lock,
  ChapterShow,
])
@TypeConverters([
  KConverter,
  CrKConverter,
  DateTimeConverter,
  DateConverter,
  VerseVersionTypeConverter,
  VersionReasonConverter,
])
abstract class AppDatabase extends FloorDatabase {
  BookContentVersionDao get bookContentVersionDao;

  BookDao get bookDao;

  ChapterContentVersionDao get chapterContentVersionDao;

  ChapterDao get chapterDao;

  ClassroomDao get classroomDao;

  CrKvDao get crKvDao;

  LockDao get lockDao;

  GameUserDao get gameUserDao;

  GameDao get gameDao;

  GameUserInputDao get gameUserInputDao;

  KvDao get kvDao;

  TimeStatsDao get timeStatsDao;

  ScheduleDao get scheduleDao;

  VerseContentVersionDao get verseContentVersionDao;

  VerseDao get verseDao;

  StatsDao get statsDao;

  VerseReviewDao get verseReviewDao;

  VerseStatsDao get verseStatsDao;

  VerseTodayPrgDao get verseTodayPrgDao;
}

class Db {
  static const String fileName = "app_database.db";

  Db._internal();

  factory Db() => _instance;
  static final Db _instance = Db._internal();

  late AppDatabase db;

  Future<AppDatabase> init({bool inMemory = false}) async {
    if (inMemory) {
      db = await $FloorAppDatabase.inMemoryDatabaseBuilder().build();
    } else {
      db = await $FloorAppDatabase.databaseBuilder(fileName).addMigrations([
        m1_2,
        m2_3,
      ]).build();
      log("Database path: \n${await sqflite.getDatabasesPath()}/$fileName");
    }
    db.lockDao.insertLock(Lock(1));
    return db;
  }
}

void prepareDb(AppDatabase db) {
  db.gameUserDao.db = db;
  db.gameDao.db = db;
  db.kvDao.db = db;
  db.chapterContentVersionDao.db = db;
  db.chapterDao.db = db;
  db.classroomDao.db = db;
  db.bookDao.db = db;
  db.scheduleDao.db = db;
  db.statsDao.db = db;
  db.verseDao.db = db;
}
