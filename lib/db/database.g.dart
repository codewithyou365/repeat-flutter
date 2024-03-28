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
            'CREATE TABLE IF NOT EXISTS `CacheFile` (`url` TEXT NOT NULL, `success` INTEGER NOT NULL, `msg` TEXT NOT NULL, PRIMARY KEY (`url`))');

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
                  'success': item.success ? 1 : 0,
                  'msg': item.msg
                }),
        _cacheFileUpdateAdapter = UpdateAdapter(
            database,
            'CacheFile',
            ['url'],
            (CacheFile item) => <String, Object?>{
                  'url': item.url,
                  'success': item.success ? 1 : 0,
                  'msg': item.msg
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<CacheFile> _cacheFileInsertionAdapter;

  final UpdateAdapter<CacheFile> _cacheFileUpdateAdapter;

  @override
  Future<CacheFile?> one() async {
    return _queryAdapter.query('SELECT * FROM CacheFile limit 1',
        mapper: (Map<String, Object?> row) => CacheFile(
            row['url'] as String, (row['success'] as int) != 0,
            msg: row['msg'] as String));
  }

  @override
  Future<void> insertCacheFile(CacheFile settings) async {
    await _cacheFileInsertionAdapter.insert(
        settings, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateCacheFile(CacheFile settings) async {
    await _cacheFileUpdateAdapter.update(settings, OnConflictStrategy.replace);
  }
}
