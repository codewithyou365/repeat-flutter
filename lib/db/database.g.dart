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
            'CREATE TABLE IF NOT EXISTS `Segment` (`key` TEXT NOT NULL, `indexFileId` INTEGER NOT NULL, `mediaFileId` INTEGER NOT NULL, `lessonIndex` INTEGER NOT NULL, `segmentIndex` INTEGER NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentOverallPrg` (`key` TEXT NOT NULL, `next` INTEGER NOT NULL, `progress` INTEGER NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentTodayPrg` (`key` TEXT NOT NULL, `sort` INTEGER NOT NULL, `progress` INTEGER NOT NULL, `viewTime` INTEGER NOT NULL, `createTime` INTEGER NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `` (`indexFileUrl` TEXT NOT NULL, `indexFilePath` TEXT NOT NULL, `mediaFilePath` TEXT NOT NULL, `key` TEXT NOT NULL, `indexFileId` INTEGER NOT NULL, `mediaFileId` INTEGER NOT NULL, `lessonIndex` INTEGER NOT NULL, `segmentIndex` INTEGER NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentReview` (`key` TEXT NOT NULL, `count` INTEGER NOT NULL, `createDate` INTEGER NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Id99999` (`id` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Lock` (`id` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE UNIQUE INDEX `index_CacheFile_url` ON `CacheFile` (`url`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_ContentIndex_sort` ON `ContentIndex` (`sort`)');
        await database.execute(
            'CREATE INDEX `index_SegmentOverallPrg_next_progress_sort` ON `SegmentOverallPrg` (`next`, `progress`, `sort`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_SegmentOverallPrg_sort` ON `SegmentOverallPrg` (`sort`)');
        await database.execute(
            'CREATE INDEX `index_SegmentReview_createDate` ON `SegmentReview` (`createDate`)');

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
        _segmentTodayPrgInsertionAdapter = InsertionAdapter(
            database,
            'SegmentTodayPrg',
            (SegmentTodayPrg item) => <String, Object?>{
                  'key': item.key,
                  'sort': item.sort,
                  'progress': item.progress,
                  'viewTime': _dateTimeConverter.encode(item.viewTime),
                  'createTime': _dateTimeConverter.encode(item.createTime)
                }),
        _segmentReviewInsertionAdapter = InsertionAdapter(
            database,
            'SegmentReview',
            (SegmentReview item) => <String, Object?>{
                  'key': item.key,
                  'count': item.count,
                  'createDate': item.createDate
                }),
        _segmentInsertionAdapter = InsertionAdapter(
            database,
            'Segment',
            (Segment item) => <String, Object?>{
                  'key': item.key,
                  'indexFileId': item.indexFileId,
                  'mediaFileId': item.mediaFileId,
                  'lessonIndex': item.lessonIndex,
                  'segmentIndex': item.segmentIndex
                }),
        _segmentOverallPrgInsertionAdapter = InsertionAdapter(
            database,
            'SegmentOverallPrg',
            (SegmentOverallPrg item) => <String, Object?>{
                  'key': item.key,
                  'next': _dateTimeConverter.encode(item.next),
                  'progress': item.progress,
                  'sort': item.sort
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<SegmentTodayPrg> _segmentTodayPrgInsertionAdapter;

  final InsertionAdapter<SegmentReview> _segmentReviewInsertionAdapter;

  final InsertionAdapter<Segment> _segmentInsertionAdapter;

  final InsertionAdapter<SegmentOverallPrg> _segmentOverallPrgInsertionAdapter;

  @override
  Future<void> forUpdate() async {
    await _queryAdapter
        .queryNoReturn('SELECT * FROM Lock where id=1 for update');
  }

  @override
  Future<int?> totalSegmentTodayPrg() async {
    return _queryAdapter.query('SELECT count(1) FROM SegmentTodayPrg',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<List<String>> findAllSegmentTodayPrg() async {
    return _queryAdapter.queryList('SELECT `key` FROM SegmentTodayPrg',
        mapper: (Map<String, Object?> row) => row.values.first as String);
  }

  @override
  Future<SegmentTodayPrg?> findOneSegmentTodayPrg() async {
    return _queryAdapter.query('SELECT * FROM SegmentTodayPrg limit 1',
        mapper: (Map<String, Object?> row) => SegmentTodayPrg(
            row['key'] as String,
            row['sort'] as int,
            row['progress'] as int,
            _dateTimeConverter.decode(row['viewTime'] as int),
            _dateTimeConverter.decode(row['createTime'] as int)));
  }

  @override
  Future<void> deleteSegmentTodayPrg() async {
    await _queryAdapter.queryNoReturn('DELETE FROM SegmentTodayPrg');
  }

  @override
  Future<List<SegmentTodayPrg>> findSegmentTodayPrg(int maxProgress) async {
    return _queryAdapter.queryList(
        'SELECT * FROM SegmentTodayPrg where progress<?1 order by viewTime,sort asc',
        mapper: (Map<String, Object?> row) => SegmentTodayPrg(row['key'] as String, row['sort'] as int, row['progress'] as int, _dateTimeConverter.decode(row['viewTime'] as int), _dateTimeConverter.decode(row['createTime'] as int)),
        arguments: [maxProgress]);
  }

  @override
  Future<int?> findLearnedCount(int now) async {
    return _queryAdapter.query(
        'SELECT count(1) FROM SegmentReview JOIN SegmentOverallPrg ON SegmentOverallPrg.`key` = SegmentReview.`key` WHERE SegmentReview.createDate=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [now]);
  }

  @override
  Future<List<SegmentOverallPrg>> findLearned(int now) async {
    return _queryAdapter.queryList(
        'SELECT  SegmentOverallPrg.* FROM SegmentReview JOIN SegmentOverallPrg ON SegmentOverallPrg.`key` = SegmentReview.`key` WHERE SegmentReview.createDate=?1',
        mapper: (Map<String, Object?> row) => SegmentOverallPrg(row['key'] as String, _dateTimeConverter.decode(row['next'] as int), row['progress'] as int, row['sort'] as int),
        arguments: [now]);
  }

  @override
  Future<List<SegmentOverallPrg>> findSegmentOverallPrg(
    int limit,
    DateTime now,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM SegmentOverallPrg where next<?2 order by progress,sort limit ?1',
        mapper: (Map<String, Object?> row) => SegmentOverallPrg(row['key'] as String, _dateTimeConverter.decode(row['next'] as int), row['progress'] as int, row['sort'] as int),
        arguments: [limit, _dateTimeConverter.encode(now)]);
  }

  @override
  Future<int?> findSegmentOverallPrgCount(
    int limit,
    DateTime now,
  ) async {
    return _queryAdapter.query(
        'SELECT count(1) FROM SegmentOverallPrg where next<?2 order by progress,sort limit ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [limit, _dateTimeConverter.encode(now)]);
  }

  @override
  Future<void> setSegmentOverallPrg(
    String key,
    int progress,
    DateTime next,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE SegmentOverallPrg SET progress=?2,next=?3 WHERE `key`=?1',
        arguments: [key, progress, _dateTimeConverter.encode(next)]);
  }

  @override
  Future<void> setSegmentTodayPrg(
    String key,
    int progress,
    DateTime viewTime,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE SegmentTodayPrg SET progress=?2,viewTime=?3 WHERE `key`=?1',
        arguments: [key, progress, _dateTimeConverter.encode(viewTime)]);
  }

  @override
  Future<SegmentOverallPrg?> getSegmentOverallPrg(String key) async {
    return _queryAdapter.query('SELECT * FROM SegmentOverallPrg WHERE `key`=?1',
        mapper: (Map<String, Object?> row) => SegmentOverallPrg(
            row['key'] as String,
            _dateTimeConverter.decode(row['next'] as int),
            row['progress'] as int,
            row['sort'] as int),
        arguments: [key]);
  }

  @override
  Future<List<String>> findTodaySegmentReview(int now) async {
    return _queryAdapter.queryList(
        'SELECT `key` FROM SegmentReview on SegmentReview.createTime=?1',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [now]);
  }

  @override
  Future<SegmentContentInDb?> getSegmentContent(String key) async {
    return _queryAdapter.query(
        'SELECT Segment.`key` `key`,indexFile.id indexFileId,mediaFile.id mediaFileId,Segment.lessonIndex lessonIndex,Segment.segmentIndex segmentIndex,indexFile.url indexFileUrl,indexFile.path indexFilePath,mediaFile.path mediaFilePath FROM Segment JOIN CacheFile indexFile ON indexFile.id=Segment.indexFileId JOIN CacheFile mediaFile ON mediaFile.id=Segment.mediaFileId WHERE Segment.`key`=?1',
        mapper: (Map<String, Object?> row) => SegmentContentInDb(row['key'] as String, row['indexFileId'] as int, row['mediaFileId'] as int, row['lessonIndex'] as int, row['segmentIndex'] as int, row['indexFileUrl'] as String, row['indexFilePath'] as String, row['mediaFilePath'] as String),
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
  Future<void> insertSegmentTodayPrg(List<SegmentTodayPrg> entities) async {
    await _segmentTodayPrgInsertionAdapter.insertList(
        entities, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertSegmentReview(List<SegmentReview> review) async {
    await _segmentReviewInsertionAdapter.insertList(
        review, OnConflictStrategy.ignore);
  }

  @override
  Future<void> insertSegments(List<Segment> entities) async {
    await _segmentInsertionAdapter.insertList(
        entities, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertSegmentOverallPrgs(
      List<SegmentOverallPrg> entities) async {
    await _segmentOverallPrgInsertionAdapter.insertList(
        entities, OnConflictStrategy.replace);
  }

  @override
  Future<List<SegmentTodayPrg>> initToday() async {
    if (database is sqflite.Transaction) {
      return super.initToday();
    } else {
      return (database as sqflite.Database)
          .transaction<List<SegmentTodayPrg>>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        return transactionDatabase.scheduleDao.initToday();
      });
    }
  }

  @override
  Future<void> error(SegmentTodayPrg scheduleCurrent) async {
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
  Future<void> right(SegmentTodayPrg segmentTodayPrg) async {
    if (database is sqflite.Transaction) {
      await super.right(segmentTodayPrg);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.scheduleDao.right(segmentTodayPrg);
      });
    }
  }

  @override
  Future<List<String>> finishCurrent() async {
    if (database is sqflite.Transaction) {
      return super.finishCurrent();
    } else {
      return (database as sqflite.Database)
          .transaction<List<String>>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        return transactionDatabase.scheduleDao.finishCurrent();
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
