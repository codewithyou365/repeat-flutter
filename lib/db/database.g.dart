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

  Id99999Dao? _id99999DaoInstance;

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
            'CREATE TABLE IF NOT EXISTS `CacheFile` (`url` TEXT NOT NULL, `path` TEXT NOT NULL, `count` INTEGER NOT NULL, `total` INTEGER NOT NULL, `msg` TEXT NOT NULL, PRIMARY KEY (`url`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ContentIndex` (`url` TEXT NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`url`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Schedule` (`key` TEXT NOT NULL, `progress` INTEGER NOT NULL, `next` INTEGER NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Id99999` (`id` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE UNIQUE INDEX `index_ContentIndex_sort` ON `ContentIndex` (`sort`)');

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
  Id99999Dao get id99999Dao {
    return _id99999DaoInstance ??= _$Id99999Dao(database, changeListener);
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
                  'url': item.url,
                  'path': item.path,
                  'count': item.count,
                  'total': item.total,
                  'msg': item.msg
                }),
        _cacheFileUpdateAdapter = UpdateAdapter(
            database,
            'CacheFile',
            ['url'],
            (CacheFile item) => <String, Object?>{
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

  final UpdateAdapter<CacheFile> _cacheFileUpdateAdapter;

  @override
  Future<CacheFile?> one(String url) async {
    return _queryAdapter.query('SELECT * FROM CacheFile WHERE url = ?1',
        mapper: (Map<String, Object?> row) => CacheFile(
            row['url'] as String, row['path'] as String,
            msg: row['msg'] as String,
            count: row['count'] as int,
            total: row['total'] as int),
        arguments: [url]);
  }

  @override
  Future<void> updateProgressByUrl(
    String url,
    int count,
    int total,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE OR ABORT CacheFile SET count=?2,total=?3 WHERE url = ?1',
        arguments: [url, count, total]);
  }

  @override
  Future<void> updateFinish(
    String url,
    String path,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE OR ABORT CacheFile SET count=total,path=?2 WHERE url = ?1',
        arguments: [url, path]);
  }

  @override
  Future<void> insertCacheFile(CacheFile data) async {
    await _cacheFileInsertionAdapter.insert(data, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateCacheFile(CacheFile data) async {
    await _cacheFileUpdateAdapter.update(data, OnConflictStrategy.replace);
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
        _scheduleInsertionAdapter = InsertionAdapter(
            database,
            'Schedule',
            (Schedule item) => <String, Object?>{
                  'key': item.key,
                  'progress': item.progress,
                  'next': item.next,
                  'sort': item.sort
                }),
        _scheduleUpdateAdapter = UpdateAdapter(
            database,
            'Schedule',
            ['key'],
            (Schedule item) => <String, Object?>{
                  'key': item.key,
                  'progress': item.progress,
                  'next': item.next,
                  'sort': item.sort
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Schedule> _scheduleInsertionAdapter;

  final UpdateAdapter<Schedule> _scheduleUpdateAdapter;

  @override
  Future<Schedule?> one(String url) async {
    return _queryAdapter.query('SELECT * FROM Schedule WHERE url = ?1',
        mapper: (Map<String, Object?> row) => Schedule(row['key'] as String,
            row['progress'] as int, row['next'] as int, row['sort'] as int),
        arguments: [url]);
  }

  @override
  Future<void> updateProgressByUrl(
    String url,
    int count,
    int total,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE OR ABORT Schedule SET count=?2,total=?3 WHERE url = ?1',
        arguments: [url, count, total]);
  }

  @override
  Future<void> updateFinish(
    String url,
    String path,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE OR ABORT Schedule SET count=total,path=?2 WHERE url = ?1',
        arguments: [url, path]);
  }

  @override
  Future<void> insertSchedule(Schedule data) async {
    await _scheduleInsertionAdapter.insert(data, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertSchedules(List<Schedule> entities) async {
    await _scheduleInsertionAdapter.insertList(
        entities, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateSchedule(Schedule data) async {
    await _scheduleUpdateAdapter.update(data, OnConflictStrategy.replace);
  }
}

class _$Id99999Dao extends Id99999Dao {
  _$Id99999Dao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _id99999InsertionAdapter = InsertionAdapter(database, 'Id99999',
            (Id99999 item) => <String, Object?>{'id': item.id});

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Id99999> _id99999InsertionAdapter;

  @override
  Future<Id99999?> one() async {
    return _queryAdapter.query('SELECT * FROM Id99999 limit 1',
        mapper: (Map<String, Object?> row) => Id99999(row['id'] as int));
  }

  @override
  Future<void> insertSchedules(List<Id99999> entities) async {
    await _id99999InsertionAdapter.insertList(
        entities, OnConflictStrategy.replace);
  }
}
