// database.dart

// required package imports
import 'dart:async';
import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/dao/cache_file_dao.dart';
import 'package:repeat_flutter/db/dao/content_index_dao.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/dao/settings_dao.dart';
import 'package:repeat_flutter/db/entity/cache_file.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
import 'package:repeat_flutter/db/entity/schedule.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'entity/settings.dart';

part 'database.g.dart'; // the generated code will be there

@Database(version: 1, entities: [Settings, CacheFile, ContentIndex, Schedule])
abstract class AppDatabase extends FloorDatabase {
  SettingsDao get settingsDao;

  CacheFileDao get cacheFileDao;

  ContentIndexDao get contentIndexDao;

  ScheduleDao get scheduleDao;
}

class Db {
  Db._internal();

  factory Db() => _instance;
  static final Db _instance = Db._internal();

  late AppDatabase db;

  Future<AppDatabase> init() async {
    db = await $FloorAppDatabase.databaseBuilder('app_database.db').build();
    return db;
  }
}
