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

  KvDao? _kvDaoInstance;

  DocDao? _docDaoInstance;

  ContentIndexDao? _contentIndexDaoInstance;

  ScheduleDao? _scheduleDaoInstance;

  BaseDao? _baseDaoInstance;

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
            'CREATE TABLE IF NOT EXISTS `Kv` (`key` TEXT NOT NULL, `value` TEXT NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Doc` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `url` TEXT NOT NULL, `path` TEXT NOT NULL, `count` INTEGER NOT NULL, `total` INTEGER NOT NULL, `msg` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ContentIndex` (`url` TEXT NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`url`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Segment` (`key` TEXT NOT NULL, `indexDocId` INTEGER NOT NULL, `mediaDocId` INTEGER NOT NULL, `lessonIndex` INTEGER NOT NULL, `segmentIndex` INTEGER NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentOverallPrg` (`key` TEXT NOT NULL, `next` INTEGER NOT NULL, `progress` INTEGER NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentTodayPrg` (`key` TEXT NOT NULL, `sort` INTEGER NOT NULL, `progress` INTEGER NOT NULL, `viewTime` INTEGER NOT NULL, `createTime` INTEGER NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentReview` (`key` TEXT NOT NULL, `count` INTEGER NOT NULL, `createDate` INTEGER NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Id99999` (`id` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Lock` (`id` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database
            .execute('CREATE UNIQUE INDEX `index_Doc_url` ON `Doc` (`url`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_ContentIndex_sort` ON `ContentIndex` (`sort`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Segment_sort` ON `Segment` (`sort`)');
        await database.execute(
            'CREATE INDEX `index_SegmentOverallPrg_next_progress` ON `SegmentOverallPrg` (`next`, `progress`)');
        await database.execute(
            'CREATE INDEX `index_SegmentReview_createDate` ON `SegmentReview` (`createDate`)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  KvDao get kvDao {
    return _kvDaoInstance ??= _$KvDao(database, changeListener);
  }

  @override
  DocDao get docDao {
    return _docDaoInstance ??= _$DocDao(database, changeListener);
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
  BaseDao get baseDao {
    return _baseDaoInstance ??= _$BaseDao(database, changeListener);
  }
}

class _$KvDao extends KvDao {
  _$KvDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _kvInsertionAdapter = InsertionAdapter(
            database,
            'Kv',
            (Kv item) =>
                <String, Object?>{'key': item.key, 'value': item.value});

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Kv> _kvInsertionAdapter;

  @override
  Future<List<Kv>> find(List<String> key) async {
    const offset = 1;
    final _sqliteVariablesForKey =
        Iterable<String>.generate(key.length, (i) => '?${i + offset}')
            .join(',');
    return _queryAdapter.queryList(
        'SELECT * FROM Kv where `key` in (' + _sqliteVariablesForKey + ')',
        mapper: (Map<String, Object?> row) =>
            Kv(row['key'] as String, row['value'] as String),
        arguments: [...key]);
  }

  @override
  Future<Kv?> one(String key) async {
    return _queryAdapter.query('SELECT * FROM Kv where `key`=?1',
        mapper: (Map<String, Object?> row) =>
            Kv(row['key'] as String, row['value'] as String),
        arguments: [key]);
  }

  @override
  Future<void> insertKv(Kv kv) async {
    await _kvInsertionAdapter.insert(kv, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertKvs(List<Kv> kv) async {
    await _kvInsertionAdapter.insertList(kv, OnConflictStrategy.replace);
  }
}

class _$DocDao extends DocDao {
  _$DocDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _docInsertionAdapter = InsertionAdapter(
            database,
            'Doc',
            (Doc item) => <String, Object?>{
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

  final InsertionAdapter<Doc> _docInsertionAdapter;

  @override
  Future<void> forUpdate() async {
    await _queryAdapter
        .queryNoReturn('SELECT * FROM Lock where id=1 for update');
  }

  @override
  Future<int?> getId(String url) async {
    return _queryAdapter.query('SELECT id FROM Doc WHERE url = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [url]);
  }

  @override
  Future<String?> getPath(int id) async {
    return _queryAdapter.query('SELECT path FROM Doc WHERE id = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [id]);
  }

  @override
  Future<Doc?> one(String url) async {
    return _queryAdapter.query('SELECT * FROM Doc WHERE url = ?1',
        mapper: (Map<String, Object?> row) => Doc(
            row['url'] as String, row['path'] as String,
            id: row['id'] as int?,
            msg: row['msg'] as String,
            count: row['count'] as int,
            total: row['total'] as int),
        arguments: [url]);
  }

  @override
  Future<void> updateDoc(
    int id,
    String msg,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE OR ABORT Doc SET msg=?2 WHERE id = ?1',
        arguments: [id, msg]);
  }

  @override
  Future<void> updateProgressById(
    int id,
    int count,
    int total,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE OR ABORT Doc SET count=?2,total=?3 WHERE id = ?1',
        arguments: [id, count, total]);
  }

  @override
  Future<void> updateFinish(
    int id,
    String path,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE OR ABORT Doc SET count=total,path=?2 WHERE id = ?1',
        arguments: [id, path]);
  }

  @override
  Future<void> insertDoc(Doc data) async {
    await _docInsertionAdapter.insert(data, OnConflictStrategy.replace);
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
        return transactionDatabase.docDao.insert(url);
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
                  'createDate': _dateConverter.encode(item.createDate)
                }),
        _segmentInsertionAdapter = InsertionAdapter(
            database,
            'Segment',
            (Segment item) => <String, Object?>{
                  'key': item.key,
                  'indexDocId': item.indexDocId,
                  'mediaDocId': item.mediaDocId,
                  'lessonIndex': item.lessonIndex,
                  'segmentIndex': item.segmentIndex,
                  'sort': item.sort
                }),
        _segmentOverallPrgInsertionAdapter = InsertionAdapter(
            database,
            'SegmentOverallPrg',
            (SegmentOverallPrg item) => <String, Object?>{
                  'key': item.key,
                  'next': _dateTimeConverter.encode(item.next),
                  'progress': item.progress
                }),
        _contentIndexDeletionAdapter = DeletionAdapter(
            database,
            'ContentIndex',
            ['url'],
            (ContentIndex item) =>
                <String, Object?>{'url': item.url, 'sort': item.sort}),
        _segmentDeletionAdapter = DeletionAdapter(
            database,
            'Segment',
            ['key'],
            (Segment item) => <String, Object?>{
                  'key': item.key,
                  'indexDocId': item.indexDocId,
                  'mediaDocId': item.mediaDocId,
                  'lessonIndex': item.lessonIndex,
                  'segmentIndex': item.segmentIndex,
                  'sort': item.sort
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<SegmentTodayPrg> _segmentTodayPrgInsertionAdapter;

  final InsertionAdapter<SegmentReview> _segmentReviewInsertionAdapter;

  final InsertionAdapter<Segment> _segmentInsertionAdapter;

  final InsertionAdapter<SegmentOverallPrg> _segmentOverallPrgInsertionAdapter;

  final DeletionAdapter<ContentIndex> _contentIndexDeletionAdapter;

  final DeletionAdapter<Segment> _segmentDeletionAdapter;

  @override
  Future<void> forUpdate() async {
    await _queryAdapter
        .queryNoReturn('SELECT * FROM Lock where id=1 for update');
  }

  @override
  Future<String?> getDoc(String url) async {
    return _queryAdapter.query('SELECT path FROM Doc WHERE url = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [url]);
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
  Future<int?> findLearnedCount(Date now) async {
    return _queryAdapter.query(
        'SELECT count(1) FROM SegmentReview JOIN SegmentOverallPrg ON SegmentOverallPrg.`key` = SegmentReview.`key` JOIN Segment ON Segment.`key` = SegmentReview.`key` WHERE SegmentReview.createDate=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [_dateConverter.encode(now)]);
  }

  @override
  Future<List<SegmentOverallPrg>> findLearned(Date now) async {
    return _queryAdapter.queryList(
        'SELECT SegmentOverallPrg.* FROM SegmentReview JOIN SegmentOverallPrg ON SegmentOverallPrg.`key` = SegmentReview.`key` JOIN Segment ON Segment.`key` = SegmentReview.`key` WHERE SegmentReview.createDate=?1',
        mapper: (Map<String, Object?> row) => SegmentOverallPrg(row['key'] as String, _dateTimeConverter.decode(row['next'] as int), row['progress'] as int),
        arguments: [_dateConverter.encode(now)]);
  }

  @override
  Future<List<Segment>> scheduleToday(
    int limit,
    DateTime now,
  ) async {
    return _queryAdapter.queryList(
        'SELECT Segment.* FROM SegmentOverallPrg JOIN Segment ON Segment.`key` = SegmentOverallPrg.`key` where SegmentOverallPrg.next<?2 order by SegmentOverallPrg.progress limit ?1',
        mapper: (Map<String, Object?> row) => Segment(row['key'] as String, row['indexDocId'] as int, row['mediaDocId'] as int, row['lessonIndex'] as int, row['segmentIndex'] as int, row['sort'] as int),
        arguments: [limit, _dateTimeConverter.encode(now)]);
  }

  @override
  Future<int?> findSegmentOverallPrgCount(
    int limit,
    DateTime now,
  ) async {
    return _queryAdapter.query(
        'SELECT count(1) FROM SegmentOverallPrg JOIN Segment ON Segment.`key` = SegmentOverallPrg.`key` where next<?2 order by progress,sort limit ?1',
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
  Future<SegmentOverallPrg?> getSegmentOverallPrg(String key) async {
    return _queryAdapter.query('SELECT * FROM SegmentOverallPrg WHERE `key`=?1',
        mapper: (Map<String, Object?> row) => SegmentOverallPrg(
            row['key'] as String,
            _dateTimeConverter.decode(row['next'] as int),
            row['progress'] as int),
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
        'SELECT Segment.`key` `key`,indexDoc.id  indexDocId,mediaDoc.id mediaDocId,Segment.lessonIndex lessonIndex,Segment.segmentIndex segmentIndex,Segment.sort sort,indexDoc.url indexDocUrl,indexDoc.path indexDocPath,mediaDoc.path mediaDocPath FROM Segment JOIN Doc indexDoc ON indexDoc.id=Segment.indexDocId JOIN Doc mediaDoc ON mediaDoc.id=Segment.mediaDocId WHERE Segment.`key`=?1',
        mapper: (Map<String, Object?> row) => SegmentContentInDb(row['key'] as String, row['indexDocId'] as int, row['mediaDocId'] as int, row['lessonIndex'] as int, row['segmentIndex'] as int, row['sort'] as int, row['indexDocUrl'] as String, row['indexDocPath'] as String, row['mediaDocPath'] as String),
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
        entities, OnConflictStrategy.ignore);
  }

  @override
  Future<void> deleteContentIndex(ContentIndex data) async {
    await _contentIndexDeletionAdapter.delete(data);
  }

  @override
  Future<void> deleteSegments(List<Segment> data) async {
    await _segmentDeletionAdapter.deleteList(data);
  }

  @override
  Future<void> importSegment(
    List<Segment> segments,
    List<SegmentOverallPrg> segmentOverallPrgs,
  ) async {
    if (database is sqflite.Transaction) {
      await super.importSegment(segments, segmentOverallPrgs);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.scheduleDao
            .importSegment(segments, segmentOverallPrgs);
      });
    }
  }

  @override
  Future<void> deleteContent(
    String url,
    List<Segment> segments,
  ) async {
    if (database is sqflite.Transaction) {
      await super.deleteContent(url, segments);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.scheduleDao.deleteContent(url, segments);
      });
    }
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
        await transactionDatabase.baseDao.initData();
      });
    }
  }
}

// ignore_for_file: unused_element
final _dateTimeConverter = DateTimeConverter();
final _dateConverter = DateConverter();
