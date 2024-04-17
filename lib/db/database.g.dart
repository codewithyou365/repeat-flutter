// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  /// Adds migrations to the builder.
  _$AppDatabaseBuilder addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  /// Adds a database [Callback] to the builder.
  _$AppDatabaseBuilder addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  /// Creates the database and initializes it.
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  SettingsDao? _settingsDaoInstance;

  CacheFileDao? _cacheFileDaoInstance;

  ContentIndexDao? _contentIndexDaoInstance;

  ScheduleDao? _scheduleDaoInstance;

  BaseDao? _baseServiceInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Settings` (`id` INTEGER NOT NULL, `themeMode` TEXT NOT NULL, `i18n` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `CacheFile` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `url` TEXT NOT NULL, `path` TEXT NOT NULL, `count` INTEGER NOT NULL, `total` INTEGER NOT NULL, `msg` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ContentIndex` (`url` TEXT NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`url`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Schedule` (`key` TEXT NOT NULL, `indexFileId` INTEGER NOT NULL, `mediaFileId` INTEGER NOT NULL, `lessonIndex` INTEGER NOT NULL, `segmentIndex` INTEGER NOT NULL, `progress` INTEGER NOT NULL, `next` INTEGER NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ScheduleCurrent` (`key` TEXT NOT NULL, `sort` INTEGER NOT NULL, `progress` INTEGER NOT NULL, `viewTime` INTEGER NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ScheduleToday` (`key` TEXT NOT NULL, `sort` INTEGER NOT NULL, `fullTime` INTEGER NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Id99999` (`id` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Lock` (`id` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE UNIQUE INDEX `index_CacheFile_url` ON `CacheFile` (`url`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_ContentIndex_sort` ON `ContentIndex` (`sort`)');
        await database.execute(
            'CREATE INDEX `index_Schedule_next` ON `Schedule` (`next`)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  SettingsDao get settingsDao {
    return _settingsDaoInstance ??= _$SettingsDao(database, changeListener);
  }

  @override
  CacheFileDao get cacheFileDao {
    return _cacheFileDaoInstance ??= _$CacheFileDao(database, changeListener);
  }

  @override
  ContentIndexDao get contentIndexDao {
    return _contentIndexDaoInstance ??=
        _$ContentIndexDao(database, changeListener);
  }

  @override
  ScheduleDao get scheduleDao {
    return _scheduleDaoInstance ??= _$ScheduleDao(database, changeListener);
  }

  @override
  BaseDao get baseService {
    return _baseServiceInstance ??= _$BaseDao(database, changeListener);
  }
}

class _$SettingsDao extends SettingsDao {
  _$SettingsDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _settingsInsertionAdapter = InsertionAdapter(
            database,
            'Settings',
            (Settings item) => <String, Object?>{
                  'id': item.id,
                  'themeMode': item.themeMode,
                  'i18n': item.i18n
                }),
        _settingsUpdateAdapter = UpdateAdapter(
            database,
            'Settings',
            ['id'],
            (Settings item) => <String, Object?>{
                  'id': item.id,
                  'themeMode': item.themeMode,
                  'i18n': item.i18n
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Settings> _settingsInsertionAdapter;

  final UpdateAdapter<Settings> _settingsUpdateAdapter;

  @override
  Future<Settings?> one() async {
    return _queryAdapter.query('SELECT * FROM Settings limit 1',
        mapper: (Map<String, Object?> row) => Settings(row['id'] as int,
            row['themeMode'] as String, row['i18n'] as String));
  }

  @override
  Future<void> insertSettings(Settings settings) async {
    await _settingsInsertionAdapter.insert(settings, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateSettings(Settings settings) async {
    await _settingsUpdateAdapter.update(settings, OnConflictStrategy.replace);
  }
}

class _$CacheFileDao extends CacheFileDao {
  _$CacheFileDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _cacheFileInsertionAdapter = InsertionAdapter(
            database,
            'CacheFile',
            (CacheFile item) => <String, Object?>{
                  'id': item.id,
                  'url': item.url,
                  'path': item.path,
                  'count': item.count,
                  'total': item.total,
                  'msg': item.msg
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<CacheFile> _cacheFileInsertionAdapter;

  @override
  Future<void> forUpdate() async {
    await _queryAdapter
        .queryNoReturn('SELECT * FROM Lock where id=1 for update');
  }

  @override
  Future<int?> getId(String url) async {
    return _queryAdapter.query('SELECT id FROM CacheFile WHERE url = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [url]);
  }

  @override
  Future<String?> getPath(int id) async {
    return _queryAdapter.query('SELECT path FROM CacheFile WHERE id = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [id]);
  }

  @override
  Future<CacheFile?> one(String url) async {
    return _queryAdapter.query('SELECT * FROM CacheFile WHERE url = ?1',
        mapper: (Map<String, Object?> row) => CacheFile(
            row['url'] as String, row['path'] as String,
            id: row['id'] as int?,
            msg: row['msg'] as String,
            count: row['count'] as int,
            total: row['total'] as int),
        arguments: [url]);
  }

  @override
  Future<void> updateCacheFile(
    int id,
    String msg,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE OR ABORT CacheFile SET msg=?2 WHERE id = ?1',
        arguments: [id, msg]);
  }

  @override
  Future<void> updateProgressById(
    int id,
    int count,
    int total,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE OR ABORT CacheFile SET count=?2,total=?3 WHERE id = ?1',
        arguments: [id, count, total]);
  }

  @override
  Future<void> updateFinish(
    int id,
    String path,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE OR ABORT CacheFile SET count=total,path=?2 WHERE id = ?1',
        arguments: [id, path]);
  }

  @override
  Future<void> insertCacheFile(CacheFile data) async {
    await _cacheFileInsertionAdapter.insert(data, OnConflictStrategy.replace);
  }

  @override
  Future<int> insert(String url) async {
    if (database is sqflite.Transaction) {
      return super.insert(url);
    } else {
      return (database as sqflite.Database)
          .transaction<int>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        return transactionDatabase.cacheFileDao.insert(url);
      });
    }
  }
}

class _$ContentIndexDao extends ContentIndexDao {
  _$ContentIndexDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _contentIndexInsertionAdapter = InsertionAdapter(
            database,
            'ContentIndex',
            (ContentIndex item) =>
                <String, Object?>{'url': item.url, 'sort': item.sort}),
        _contentIndexDeletionAdapter = DeletionAdapter(
            database,
            'ContentIndex',
            ['url'],
            (ContentIndex item) =>
                <String, Object?>{'url': item.url, 'sort': item.sort});

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ContentIndex> _contentIndexInsertionAdapter;

  final DeletionAdapter<ContentIndex> _contentIndexDeletionAdapter;

  @override
  Future<List<ContentIndex>> findContentIndex() async {
    return _queryAdapter.queryList('SELECT * FROM ContentIndex order by sort',
        mapper: (Map<String, Object?> row) =>
            ContentIndex(row['url'] as String, row['sort'] as int));
  }

  @override
  Future<int?> getIdleSortSequenceNumber() async {
    return _queryAdapter.query(
        'SELECT Id99999.id FROM Id99999 LEFT JOIN ContentIndex ON ContentIndex.sort = Id99999.id WHERE ContentIndex.sort IS NULL limit 1',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<void> insertContentIndex(ContentIndex data) async {
    await _contentIndexInsertionAdapter.insert(
        data, OnConflictStrategy.replace);
  }

  @override
  Future<void> deleteContentIndex(ContentIndex data) async {
    await _contentIndexDeletionAdapter.delete(data);
  }
}

class _$ScheduleDao extends ScheduleDao {
  _$ScheduleDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _scheduleTodayInsertionAdapter = InsertionAdapter(
            database,
            'ScheduleToday',
            (ScheduleToday item) => <String, Object?>{
                  'key': item.key,
                  'sort': item.sort,
                  'fullTime': _dateTimeConverter.encode(item.fullTime)
                }),
        _scheduleCurrentInsertionAdapter = InsertionAdapter(
            database,
            'ScheduleCurrent',
            (ScheduleCurrent item) => <String, Object?>{
                  'key': item.key,
                  'sort': item.sort,
                  'progress': item.progress,
                  'viewTime': _dateTimeConverter.encode(item.viewTime)
                }),
        _scheduleInsertionAdapter = InsertionAdapter(
            database,
            'Schedule',
            (Schedule item) => <String, Object?>{
                  'key': item.key,
                  'indexFileId': item.indexFileId,
                  'mediaFileId': item.mediaFileId,
                  'lessonIndex': item.lessonIndex,
                  'segmentIndex': item.segmentIndex,
                  'progress': item.progress,
                  'next': _dateTimeConverter.encode(item.next),
                  'sort': item.sort
                }),
        _scheduleCurrentDeletionAdapter = DeletionAdapter(
            database,
            'ScheduleCurrent',
            ['key'],
            (ScheduleCurrent item) => <String, Object?>{
                  'key': item.key,
                  'sort': item.sort,
                  'progress': item.progress,
                  'viewTime': _dateTimeConverter.encode(item.viewTime)
                }),
        _scheduleDeletionAdapter = DeletionAdapter(
            database,
            'Schedule',
            ['key'],
            (Schedule item) => <String, Object?>{
                  'key': item.key,
                  'indexFileId': item.indexFileId,
                  'mediaFileId': item.mediaFileId,
                  'lessonIndex': item.lessonIndex,
                  'segmentIndex': item.segmentIndex,
                  'progress': item.progress,
                  'next': _dateTimeConverter.encode(item.next),
                  'sort': item.sort
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ScheduleToday> _scheduleTodayInsertionAdapter;

  final InsertionAdapter<ScheduleCurrent> _scheduleCurrentInsertionAdapter;

  final InsertionAdapter<Schedule> _scheduleInsertionAdapter;

  final DeletionAdapter<ScheduleCurrent> _scheduleCurrentDeletionAdapter;

  final DeletionAdapter<Schedule> _scheduleDeletionAdapter;

  @override
  Future<void> forUpdate() async {
    await _queryAdapter
        .queryNoReturn('SELECT * FROM Lock where id=1 for update');
  }

  @override
  Future<ScheduleToday?> findOneScheduleToday() async {
    return _queryAdapter.query('SELECT * FROM ScheduleToday limit 1',
        mapper: (Map<String, Object?> row) => ScheduleToday(
            row['key'] as String,
            row['sort'] as int,
            _dateTimeConverter.decode(row['fullTime'] as int)));
  }

  @override
  Future<void> deleteScheduleToday() async {
    await _queryAdapter.queryNoReturn('DELETE FROM ScheduleToday');
  }

  @override
  Future<List<ScheduleToday>> findScheduleToday() async {
    return _queryAdapter.queryList('SELECT * FROM ScheduleToday order by sort',
        mapper: (Map<String, Object?> row) => ScheduleToday(
            row['key'] as String,
            row['sort'] as int,
            _dateTimeConverter.decode(row['fullTime'] as int)));
  }

  @override
  Future<int?> totalScheduleCurrent() async {
    return _queryAdapter.query('SELECT count(1) FROM ScheduleCurrent',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<List<ScheduleCurrent>> findAllScheduleCurrent() async {
    return _queryAdapter.queryList('SELECT * FROM ScheduleCurrent',
        mapper: (Map<String, Object?> row) => ScheduleCurrent(
            row['key'] as String,
            row['sort'] as int,
            row['progress'] as int,
            _dateTimeConverter.decode(row['viewTime'] as int)));
  }

  @override
  Future<ScheduleCurrent?> findOneScheduleCurrent() async {
    return _queryAdapter.query('SELECT * FROM ScheduleCurrent limit 1',
        mapper: (Map<String, Object?> row) => ScheduleCurrent(
            row['key'] as String,
            row['sort'] as int,
            row['progress'] as int,
            _dateTimeConverter.decode(row['viewTime'] as int)));
  }

  @override
  Future<void> deleteScheduleCurrent() async {
    await _queryAdapter.queryNoReturn('DELETE FROM ScheduleCurrent');
  }

  @override
  Future<List<ScheduleCurrent>> findScheduleCurrent(int maxProgress) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ScheduleCurrent where progress<?1 order by viewTime,sort asc',
        mapper: (Map<String, Object?> row) => ScheduleCurrent(row['key'] as String, row['sort'] as int, row['progress'] as int, _dateTimeConverter.decode(row['viewTime'] as int)),
        arguments: [maxProgress]);
  }

  @override
  Future<List<Schedule>> findSchedule(
    int limit,
    DateTime now,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Schedule where next<?2 order by progress,sort limit ?1',
        mapper: (Map<String, Object?> row) => Schedule(
            row['key'] as String,
            row['indexFileId'] as int,
            row['mediaFileId'] as int,
            row['lessonIndex'] as int,
            row['segmentIndex'] as int,
            row['progress'] as int,
            _dateTimeConverter.decode(row['next'] as int),
            row['sort'] as int),
        arguments: [limit, _dateTimeConverter.encode(now)]);
  }

  @override
  Future<void> setSchedule(
    String key,
    int progress,
    DateTime next,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Schedule SET progress=?2,next=?3 WHERE `key`=?1',
        arguments: [key, progress, _dateTimeConverter.encode(next)]);
  }

  @override
  Future<void> setScheduleCurrent(
    String key,
    int progress,
    DateTime viewTime,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE ScheduleCurrent SET progress=?2,viewTime=?3 WHERE `key`=?1',
        arguments: [key, progress, _dateTimeConverter.encode(viewTime)]);
  }

  @override
  Future<Schedule?> getOneSchedule(String key) async {
    return _queryAdapter.query('SELECT * FROM Schedule WHERE `key`=?1',
        mapper: (Map<String, Object?> row) => Schedule(
            row['key'] as String,
            row['indexFileId'] as int,
            row['mediaFileId'] as int,
            row['lessonIndex'] as int,
            row['segmentIndex'] as int,
            row['progress'] as int,
            _dateTimeConverter.decode(row['next'] as int),
            row['sort'] as int),
        arguments: [key]);
  }

  @override
  Future<Segment?> getSegment(String key) async {
    return _queryAdapter.query(
        'SELECT Schedule.`key` `key`,indexFile.id indexFileId,indexFile.url indexFileUrl,indexFile.path indexFilePath,Schedule.lessonIndex lessonIndex,Schedule.segmentIndex segmentIndex,mediaFile.path mediaFilePath FROM Schedule JOIN CacheFile indexFile ON indexFile.id=Schedule.indexFileId JOIN CacheFile mediaFile ON mediaFile.id=Schedule.mediaFileId WHERE Schedule.`key`=?1',
        mapper: (Map<String, Object?> row) => Segment(row['key'] as String, row['indexFileId'] as int, row['indexFileUrl'] as String, row['indexFilePath'] as String, row['lessonIndex'] as int, row['segmentIndex'] as int, row['mediaFilePath'] as String),
        arguments: [key]);
  }

  @override
  Future<ScheduleCurrent?> getOneScheduleCurrent(String key) async {
    return _queryAdapter.query('SELECT * FROM ScheduleCurrent WHERE `key`=?1',
        mapper: (Map<String, Object?> row) => ScheduleCurrent(
            row['key'] as String,
            row['sort'] as int,
            row['progress'] as int,
            _dateTimeConverter.decode(row['viewTime'] as int)),
        arguments: [key]);
  }

  @override
  Future<List<String>> findKeyByUrl(String indexUrl) async {
    return _queryAdapter.queryList(
        'SELECT `key` FROM Schedule WHERE indexUrl = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [indexUrl]);
  }

  @override
  Future<void> insertScheduleToday(List<ScheduleToday> entities) async {
    await _scheduleTodayInsertionAdapter.insertList(
        entities, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertScheduleCurrent(List<ScheduleCurrent> entities) async {
    await _scheduleCurrentInsertionAdapter.insertList(
        entities, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertSchedules(List<Schedule> entities) async {
    await _scheduleInsertionAdapter.insertList(
        entities, OnConflictStrategy.replace);
  }

  @override
  Future<void> deleteScheduleTodayByCurrent(List<ScheduleCurrent> data) async {
    await _scheduleCurrentDeletionAdapter.deleteList(data);
  }

  @override
  Future<void> deleteOneScheduleCurrent(ScheduleCurrent data) async {
    await _scheduleCurrentDeletionAdapter.delete(data);
  }

  @override
  Future<void> deleteContentIndex(List<Schedule> data) async {
    await _scheduleDeletionAdapter.deleteList(data);
  }

  @override
  Future<LearnContent> initCurrent() async {
    if (database is sqflite.Transaction) {
      return super.initCurrent();
    } else {
      return (database as sqflite.Database)
          .transaction<LearnContent>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        return transactionDatabase.scheduleDao.initCurrent();
      });
    }
  }

  @override
  Future<void> error(ScheduleCurrent scheduleCurrent) async {
    if (database is sqflite.Transaction) {
      await super.error(scheduleCurrent);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.scheduleDao.error(scheduleCurrent);
      });
    }
  }

  @override
  Future<void> right(ScheduleCurrent scheduleCurrent) async {
    if (database is sqflite.Transaction) {
      await super.right(scheduleCurrent);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.scheduleDao.right(scheduleCurrent);
      });
    }
  }

  @override
  Future<List<ScheduleCurrent>> clearCurrent() async {
    if (database is sqflite.Transaction) {
      return super.clearCurrent();
    } else {
      return (database as sqflite.Database)
          .transaction<List<ScheduleCurrent>>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        return transactionDatabase.scheduleDao.clearCurrent();
      });
    }
  }
}

class _$BaseDao extends BaseDao {
  _$BaseDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _id99999InsertionAdapter = InsertionAdapter(database, 'Id99999',
            (Id99999 item) => <String, Object?>{'id': item.id}),
        _lockInsertionAdapter = InsertionAdapter(
            database, 'Lock', (Lock item) => <String, Object?>{'id': item.id});

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Id99999> _id99999InsertionAdapter;

  final InsertionAdapter<Lock> _lockInsertionAdapter;

  @override
  Future<Id99999?> getId99999() async {
    return _queryAdapter.query('SELECT * FROM Id99999 limit 1',
        mapper: (Map<String, Object?> row) => Id99999(row['id'] as int));
  }

  @override
  Future<Lock?> getLock() async {
    return _queryAdapter.query('SELECT * FROM Lock limit 1',
        mapper: (Map<String, Object?> row) => Lock(row['id'] as int));
  }

  @override
  Future<void> insertId99999(List<Id99999> entities) async {
    await _id99999InsertionAdapter.insertList(
        entities, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertLock(Lock entity) async {
    await _lockInsertionAdapter.insert(entity, OnConflictStrategy.replace);
  }

  @override
  Future<void> initData() async {
    if (database is sqflite.Transaction) {
      await super.initData();
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.baseService.initData();
      });
    }
  }
}

// ignore_for_file: unused_element
final _dateTimeConverter = DateTimeConverter();
