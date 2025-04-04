// database.dart

// required package imports
import 'dart:async';
import 'dart:developer';
import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/dao/classroom_dao.dart';
import 'package:repeat_flutter/db/dao/content_dao.dart';
import 'package:repeat_flutter/db/dao/doc_dao.dart';
import 'package:repeat_flutter/db/dao/game_dao.dart';
import 'package:repeat_flutter/db/dao/game_user_dao.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/dao/kv_dao.dart';
import 'package:repeat_flutter/db/dao/stats_dao.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/doc.dart';
import 'package:repeat_flutter/db/entity/content.dart';
import 'package:repeat_flutter/db/entity/lock.dart';
import 'package:repeat_flutter/db/entity/segment.dart';
import 'package:repeat_flutter/db/entity/segment_key.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';
import 'package:repeat_flutter/db/entity/segment_review.dart';
import 'package:repeat_flutter/db/entity/segment_stats.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/db/entity/game.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/game_user_input.dart';
import 'package:repeat_flutter/db/entity/time_stats.dart';
import 'package:repeat_flutter/db/migration/m1_2.dart';
import 'package:repeat_flutter/db/migration/m2_3.dart';
import 'package:repeat_flutter/db/type_converter.dart';
import 'package:repeat_flutter/logic/model/segment_content.dart';
import 'package:repeat_flutter/logic/model/segment_key_id.dart';
import 'package:repeat_flutter/logic/model/segment_overall_prg_with_key.dart';
import 'package:repeat_flutter/logic/model/segment_review_with_key.dart';
import 'package:repeat_flutter/logic/model/segment_show.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'dao/base_dao.dart';
import 'entity/kv.dart';

part 'database.g.dart'; // the generated code will be there

@Database(version: 3, entities: [
  Kv,
  Doc,
  Classroom,
  Content,
  CrKv,
  Segment,
  SegmentKey,
  SegmentKeyId,
  SegmentShow,
  SegmentOverallPrg,
  SegmentOverallPrgWithKey,
  SegmentReview,
  SegmentReviewWithKey,
  SegmentTodayPrg,
  SegmentContentInDb,
  SegmentStats,
  TimeStats,
  Game,
  GameUser,
  GameUserInput,
  Lock,
])
@TypeConverters([
  KConverter,
  CrKConverter,
  DateTimeConverter,
  DateConverter,
])
abstract class AppDatabase extends FloorDatabase {
  GameUserDao get gameUserDao;

  GameDao get gameDao;

  KvDao get kvDao;

  DocDao get docDao;

  ClassroomDao get classroomDao;

  ContentDao get contentDao;

  ScheduleDao get scheduleDao;

  BaseDao get baseDao;

  StatsDao get statsDao;
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
      log("Database path: ${await sqflite.getDatabasesPath()}");
    }
    return db;
  }
}
