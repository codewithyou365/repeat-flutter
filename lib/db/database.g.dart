// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
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

  ClassroomDao? _classroomDaoInstance;

  ContentIndexDao? _contentIndexDaoInstance;

  ScheduleDao? _scheduleDaoInstance;

  BaseDao? _baseDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 2,
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
            'CREATE TABLE IF NOT EXISTS `Kv` (`k` TEXT NOT NULL, `value` TEXT NOT NULL, PRIMARY KEY (`k`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Doc` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `url` TEXT NOT NULL, `path` TEXT NOT NULL, `count` INTEGER NOT NULL, `total` INTEGER NOT NULL, `msg` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Classroom` (`name` TEXT NOT NULL, `arg` TEXT NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`name`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ContentIndex` (`crn` TEXT NOT NULL, `url` TEXT NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`crn`, `url`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `CrKv` (`crn` TEXT NOT NULL, `k` TEXT NOT NULL, `value` TEXT NOT NULL, PRIMARY KEY (`crn`, `k`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Segment` (`crn` TEXT NOT NULL, `k` TEXT NOT NULL, `indexDocId` INTEGER NOT NULL, `mediaDocId` INTEGER NOT NULL, `lessonIndex` INTEGER NOT NULL, `segmentIndex` INTEGER NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`crn`, `k`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentOverallPrg` (`crn` TEXT NOT NULL, `k` TEXT NOT NULL, `next` INTEGER NOT NULL, `progress` INTEGER NOT NULL, PRIMARY KEY (`crn`, `k`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentReview` (`crn` TEXT NOT NULL, `createDate` INTEGER NOT NULL, `k` TEXT NOT NULL, `count` INTEGER NOT NULL, PRIMARY KEY (`crn`, `createDate`, `k`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentTodayReview` (`crn` TEXT NOT NULL, `createDate` INTEGER NOT NULL, `k` TEXT NOT NULL, `count` INTEGER NOT NULL, `finish` INTEGER NOT NULL, PRIMARY KEY (`crn`, `createDate`, `k`, `count`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentCurrentPrg` (`crn` TEXT NOT NULL, `k` TEXT NOT NULL, `learnOrReview` INTEGER NOT NULL, `sort` INTEGER NOT NULL, `progress` INTEGER NOT NULL, `viewTime` INTEGER NOT NULL, PRIMARY KEY (`crn`, `k`, `learnOrReview`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Id99999` (`id` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Lock` (`id` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database
            .execute('CREATE UNIQUE INDEX `index_Doc_url` ON `Doc` (`url`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Classroom_sort` ON `Classroom` (`sort`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_ContentIndex_sort` ON `ContentIndex` (`sort`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Segment_sort` ON `Segment` (`sort`)');
        await database.execute(
            'CREATE INDEX `index_SegmentOverallPrg_next_progress` ON `SegmentOverallPrg` (`next`, `progress`)');

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
  ClassroomDao get classroomDao {
    return _classroomDaoInstance ??= _$ClassroomDao(database, changeListener);
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
            (Kv item) => <String, Object?>{
                  'k': _kConverter.encode(item.k),
                  'value': item.value
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Kv> _kvInsertionAdapter;

  @override
  Future<List<Kv>> find(List<K> k) async {
    const offset = 1;
    final _sqliteVariablesForK =
        Iterable<String>.generate(k.length, (i) => '?${i + offset}').join(',');
    return _queryAdapter.queryList(
        'SELECT * FROM Kv where `k` in (' + _sqliteVariablesForK + ')',
        mapper: (Map<String, Object?> row) =>
            Kv(_kConverter.decode(row['k'] as String), row['value'] as String),
        arguments: [...k.map((element) => _kConverter.encode(element))]);
  }

  @override
  Future<Kv?> one(K k) async {
    return _queryAdapter.query('SELECT * FROM Kv where `k`=?1',
        mapper: (Map<String, Object?> row) =>
            Kv(_kConverter.decode(row['k'] as String), row['value'] as String),
        arguments: [_kConverter.encode(k)]);
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

class _$ClassroomDao extends ClassroomDao {
  _$ClassroomDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _classroomInsertionAdapter = InsertionAdapter(
            database,
            'Classroom',
            (Classroom item) => <String, Object?>{
                  'name': item.name,
                  'arg': item.arg,
                  'sort': item.sort
                }),
        _classroomDeletionAdapter = DeletionAdapter(
            database,
            'Classroom',
            ['name'],
            (Classroom item) => <String, Object?>{
                  'name': item.name,
                  'arg': item.arg,
                  'sort': item.sort
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Classroom> _classroomInsertionAdapter;

  final DeletionAdapter<Classroom> _classroomDeletionAdapter;

  @override
  Future<void> forUpdate() async {
    await _queryAdapter
        .queryNoReturn('SELECT * FROM Lock where id=1 for update');
  }

  @override
  Future<List<Classroom>> getAllClassroom() async {
    return _queryAdapter.queryList('SELECT * FROM Classroom order by sort',
        mapper: (Map<String, Object?> row) => Classroom(
            row['name'] as String, row['arg'] as String, row['sort'] as int));
  }

  @override
  Future<int?> getIdleSortSequenceNumber() async {
    return _queryAdapter.query(
        'SELECT Id99999.id FROM Id99999 LEFT JOIN Classroom ON Classroom.sort = Id99999.id WHERE Classroom.sort IS NULL limit 1',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<void> insertClassroom(Classroom entity) async {
    await _classroomInsertionAdapter.insert(entity, OnConflictStrategy.replace);
  }

  @override
  Future<void> deleteContentIndex(Classroom data) async {
    await _classroomDeletionAdapter.delete(data);
  }

  @override
  Future<Classroom> add(String name) async {
    if (database is sqflite.Transaction) {
      return super.add(name);
    } else {
      return (database as sqflite.Database)
          .transaction<Classroom>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        return transactionDatabase.classroomDao.add(name);
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
            (ContentIndex item) => <String, Object?>{
                  'crn': item.crn,
                  'url': item.url,
                  'sort': item.sort
                }),
        _contentIndexDeletionAdapter = DeletionAdapter(
            database,
            'ContentIndex',
            ['crn', 'url'],
            (ContentIndex item) => <String, Object?>{
                  'crn': item.crn,
                  'url': item.url,
                  'sort': item.sort
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ContentIndex> _contentIndexInsertionAdapter;

  final DeletionAdapter<ContentIndex> _contentIndexDeletionAdapter;

  @override
  Future<List<ContentIndex>> findContentIndex(String crn) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ContentIndex where crn=?1 order by sort',
        mapper: (Map<String, Object?> row) => ContentIndex(
            row['crn'] as String, row['url'] as String, row['sort'] as int),
        arguments: [crn]);
  }

  @override
  Future<int?> getIdleSortSequenceNumber(String crn) async {
    return _queryAdapter.query(
        'SELECT Id99999.id FROM Id99999 LEFT JOIN ContentIndex ON ContentIndex.sort = Id99999.id WHERE where crn=?1 ContentIndex.sort IS NULL limit 1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [crn]);
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
        _crKvInsertionAdapter = InsertionAdapter(
            database,
            'CrKv',
            (CrKv item) => <String, Object?>{
                  'crn': item.crn,
                  'k': _crKConverter.encode(item.k),
                  'value': item.value
                }),
        _segmentCurrentPrgInsertionAdapter = InsertionAdapter(
            database,
            'SegmentCurrentPrg',
            (SegmentCurrentPrg item) => <String, Object?>{
                  'crn': item.crn,
                  'k': item.k,
                  'learnOrReview': item.learnOrReview ? 1 : 0,
                  'sort': item.sort,
                  'progress': item.progress,
                  'viewTime': _dateTimeConverter.encode(item.viewTime)
                }),
        _segmentTodayReviewInsertionAdapter = InsertionAdapter(
            database,
            'SegmentTodayReview',
            (SegmentTodayReview item) => <String, Object?>{
                  'crn': item.crn,
                  'createDate': _dateConverter.encode(item.createDate),
                  'k': item.k,
                  'count': item.count,
                  'finish': item.finish ? 1 : 0
                }),
        _segmentReviewInsertionAdapter = InsertionAdapter(
            database,
            'SegmentReview',
            (SegmentReview item) => <String, Object?>{
                  'crn': item.crn,
                  'createDate': _dateConverter.encode(item.createDate),
                  'k': item.k,
                  'count': item.count
                }),
        _segmentInsertionAdapter = InsertionAdapter(
            database,
            'Segment',
            (Segment item) => <String, Object?>{
                  'crn': item.crn,
                  'k': item.k,
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
                  'crn': item.crn,
                  'k': item.k,
                  'next': _dateConverter.encode(item.next),
                  'progress': item.progress
                }),
        _contentIndexDeletionAdapter = DeletionAdapter(
            database,
            'ContentIndex',
            ['crn', 'url'],
            (ContentIndex item) => <String, Object?>{
                  'crn': item.crn,
                  'url': item.url,
                  'sort': item.sort
                }),
        _segmentDeletionAdapter = DeletionAdapter(
            database,
            'Segment',
            ['crn', 'k'],
            (Segment item) => <String, Object?>{
                  'crn': item.crn,
                  'k': item.k,
                  'indexDocId': item.indexDocId,
                  'mediaDocId': item.mediaDocId,
                  'lessonIndex': item.lessonIndex,
                  'segmentIndex': item.segmentIndex,
                  'sort': item.sort
                }),
        _crKvDeletionAdapter = DeletionAdapter(
            database,
            'CrKv',
            ['crn', 'k'],
            (CrKv item) => <String, Object?>{
                  'crn': item.crn,
                  'k': _crKConverter.encode(item.k),
                  'value': item.value
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<CrKv> _crKvInsertionAdapter;

  final InsertionAdapter<SegmentCurrentPrg> _segmentCurrentPrgInsertionAdapter;

  final InsertionAdapter<SegmentTodayReview>
      _segmentTodayReviewInsertionAdapter;

  final InsertionAdapter<SegmentReview> _segmentReviewInsertionAdapter;

  final InsertionAdapter<Segment> _segmentInsertionAdapter;

  final InsertionAdapter<SegmentOverallPrg> _segmentOverallPrgInsertionAdapter;

  final DeletionAdapter<ContentIndex> _contentIndexDeletionAdapter;

  final DeletionAdapter<Segment> _segmentDeletionAdapter;

  final DeletionAdapter<CrKv> _crKvDeletionAdapter;

  @override
  Future<void> forUpdate() async {
    await _queryAdapter
        .queryNoReturn('SELECT * FROM Lock where id=1 for update');
  }

  @override
  Future<int?> totalSegmentCurrentPrg(
    String crn,
    bool learnOrReview,
  ) async {
    return _queryAdapter.query(
        'SELECT count(1) FROM SegmentCurrentPrg where crn=?1 and learnOrReview=?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [crn, learnOrReview ? 1 : 0]);
  }

  @override
  Future<List<SegmentCurrentPrg>> findAllSegmentCurrentPrg(
    String crn,
    bool learnOrReview,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM SegmentCurrentPrg where crn=?1 and learnOrReview=?2',
        mapper: (Map<String, Object?> row) => SegmentCurrentPrg(
            row['crn'] as String,
            row['k'] as String,
            (row['learnOrReview'] as int) != 0,
            row['sort'] as int,
            row['progress'] as int,
            _dateTimeConverter.decode(row['viewTime'] as int)),
        arguments: [crn, learnOrReview ? 1 : 0]);
  }

  @override
  Future<int?> value(
    String crn,
    CrK k,
  ) async {
    return _queryAdapter.query(
        'SELECT CAST(value as INTEGER) FROM CrKv WHERE crn=?1 and `k`=?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [crn, _crKConverter.encode(k)]);
  }

  @override
  Future<SegmentCurrentPrg?> findOneSegmentCurrentPrg(
    String crn,
    bool learnOrReview,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM SegmentCurrentPrg where crn=?1 and learnOrReview=?2 limit 1',
        mapper: (Map<String, Object?> row) => SegmentCurrentPrg(row['crn'] as String, row['k'] as String, (row['learnOrReview'] as int) != 0, row['sort'] as int, row['progress'] as int, _dateTimeConverter.decode(row['viewTime'] as int)),
        arguments: [crn, learnOrReview ? 1 : 0]);
  }

  @override
  Future<void> deleteSegmentCurrentPrg(
    String crn,
    bool learnOrReview,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM SegmentCurrentPrg where crn=?1 and learnOrReview=?2',
        arguments: [crn, learnOrReview ? 1 : 0]);
  }

  @override
  Future<void> deleteAllSegmentCurrentPrg(String crn) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM SegmentCurrentPrg where crn=?1',
        arguments: [crn]);
  }

  @override
  Future<List<SegmentCurrentPrg>> findSegmentCurrentPrg(
    String crn,
    bool learnOrReview,
    int maxProgress,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM SegmentCurrentPrg where crn=?1 and learnOrReview=?2 and progress<?3 order by viewTime,sort asc',
        mapper: (Map<String, Object?> row) => SegmentCurrentPrg(row['crn'] as String, row['k'] as String, (row['learnOrReview'] as int) != 0, row['sort'] as int, row['progress'] as int, _dateTimeConverter.decode(row['viewTime'] as int)),
        arguments: [crn, learnOrReview ? 1 : 0, maxProgress]);
  }

  @override
  Future<void> setSegmentCurrentPrg(
    String crn,
    String k,
    bool learnOrReview,
    int progress,
    DateTime viewTime,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE SegmentCurrentPrg SET progress=?4,viewTime=?5 WHERE crn=?1 and `k`=?2 and learnOrReview=?3',
        arguments: [
          crn,
          k,
          learnOrReview ? 1 : 0,
          progress,
          _dateTimeConverter.encode(viewTime)
        ]);
  }

  @override
  Future<int?> findLearnedCount(
    String crn,
    Date now,
  ) async {
    return _queryAdapter.query(
        'SELECT count(1) FROM SegmentReview JOIN SegmentOverallPrg ON SegmentOverallPrg.crn=?1 and SegmentOverallPrg.`k` = SegmentReview.`k` JOIN Segment ON Segment.crn=?1 and Segment.`k` = SegmentReview.`k` WHERE SegmentReview.createDate=?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [crn, _dateConverter.encode(now)]);
  }

  @override
  Future<List<SegmentOverallPrg>> findLearned(
    String crn,
    Date now,
  ) async {
    return _queryAdapter.queryList(
        'SELECT SegmentOverallPrg.* FROM SegmentReview JOIN SegmentOverallPrg ON SegmentOverallPrg.crn=?1 and SegmentOverallPrg.`k` = SegmentReview.`k` JOIN Segment ON Segment.crn=?1 and Segment.`k` = SegmentReview.`k` WHERE SegmentReview.crn=?1 and SegmentReview.createDate=?2',
        mapper: (Map<String, Object?> row) => SegmentOverallPrg(row['crn'] as String, row['k'] as String, _dateConverter.decode(row['next'] as int), row['progress'] as int),
        arguments: [crn, _dateConverter.encode(now)]);
  }

  @override
  Future<void> deleteSegmentTodayReview(String crn) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM SegmentTodayReview where crn=?1',
        arguments: [crn]);
  }

  @override
  Future<List<String>> todayFinishReviewed(
    String crn,
    Date now,
    int count,
  ) async {
    return _queryAdapter.queryList(
        'SELECT SegmentReview.k FROM SegmentTodayReview JOIN SegmentReview ON SegmentReview.crn=?1  AND SegmentReview.createDate = SegmentTodayReview.createDate  ANd SegmentReview.`k` = SegmentTodayReview.`k` JOIN Segment ON Segment.crn=?1 and Segment.`k` = SegmentReview.`k` WHERE SegmentTodayReview.crn=?1 and SegmentTodayReview.createDate=?2 AND SegmentTodayReview.finish=true AND SegmentTodayReview.count=?3',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [crn, _dateConverter.encode(now), count]);
  }

  @override
  Future<SegmentTodayReview?> findTodayReviewUnfinished(String crn) async {
    return _queryAdapter.query(
        'SELECT * FROM SegmentTodayReview WHERE SegmentTodayReview.crn=?1 and SegmentTodayReview.finish=false limit 1',
        mapper: (Map<String, Object?> row) => SegmentTodayReview(row['crn'] as String, _dateConverter.decode(row['createDate'] as int), row['k'] as String, row['count'] as int, (row['finish'] as int) != 0),
        arguments: [crn]);
  }

  @override
  Future<void> setSegmentTodayReviewFinish(
    String crn,
    List<Date> createDate,
    String k,
  ) async {
    const offset = 3;
    final _sqliteVariablesForCreateDate =
        Iterable<String>.generate(createDate.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'UPDATE SegmentTodayReview SET finish=1 WHERE crn=?1 createDate in (' +
            _sqliteVariablesForCreateDate +
            ') and `k`=?2',
        arguments: [
          crn,
          k,
          ...createDate.map((element) => _dateConverter.encode(element))
        ]);
  }

  @override
  Future<int?> findReviewedMinCreateDate(
    String crn,
    int reviewCount,
    Date now,
  ) async {
    return _queryAdapter.query(
        'SELECT ifnull(min(createDate),-1) FROM SegmentReview JOIN Segment ON Segment.crn=?1 and Segment.`k` = SegmentReview.`k` WHERE SegmentReview.crn=?1 and SegmentReview.count=?2 and SegmentReview.createDate<=?3 order by createDate',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [crn, reviewCount, _dateConverter.encode(now)]);
  }

  @override
  Future<List<SegmentReviewContentInDb>> shouldTodayReview(
    String crn,
    int reviewCount,
    Date startDate,
    Date endDate,
  ) async {
    return _queryAdapter.queryList(
        'SELECT Segment.crn,Segment.k,Segment.sort,SegmentReviewKey.createDate reviewCreateDate,SegmentReviewKey.count reviewCount FROM Segment JOIN (SELECT `k`  ,group_concat(createDate) createDate  ,min(SegmentReview.count) count  FROM SegmentReview  WHERE SegmentReview.crn=?1  and SegmentReview.count=?2  and SegmentReview.createDate>=?3  and SegmentReview.createDate<=?4  group by SegmentReview.k) SegmentReviewKey on SegmentReviewKey.`k`=Segment.`k` WHERE Segment.crn=?1 order by sort',
        mapper: (Map<String, Object?> row) => SegmentReviewContentInDb(
            row['crn'] as String,
            row['k'] as String,
            row['sort'] as int,
            row['reviewCount'] as int,
            row['reviewCreateDate'] as String),
        arguments: [
          crn,
          reviewCount,
          _dateConverter.encode(startDate),
          _dateConverter.encode(endDate)
        ]);
  }

  @override
  Future<List<SegmentReviewContentInDb>> scheduleLearnToday(
    String crn,
    int limit,
    Date now,
  ) async {
    return _queryAdapter.queryList(
        'SELECT Segment.crn,Segment.k,Segment.sort,\'0\' reviewCreateDate,0 reviewCount FROM SegmentOverallPrg JOIN Segment ON Segment.crn=?1  and Segment.`k` = SegmentOverallPrg.`k` where Segment.crn=?1 and SegmentOverallPrg.next<=?3 order by SegmentOverallPrg.progress limit ?2',
        mapper: (Map<String, Object?> row) => SegmentReviewContentInDb(row['crn'] as String, row['k'] as String, row['sort'] as int, row['reviewCount'] as int, row['reviewCreateDate'] as String),
        arguments: [crn, limit, _dateConverter.encode(now)]);
  }

  @override
  Future<int?> findSegmentOverallPrgCount(
    String crn,
    int limit,
    Date now,
  ) async {
    return _queryAdapter.query(
        'SELECT count(1) FROM SegmentOverallPrg JOIN Segment ON Segment.crn=?1 and Segment.`k` = SegmentOverallPrg.`k` where SegmentOverallPrg.crn=?1 and next<=?3 order by progress,sort limit ?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [crn, limit, _dateConverter.encode(now)]);
  }

  @override
  Future<void> setPrgAndNext4Sop(
    String crn,
    String k,
    int progress,
    Date next,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE SegmentOverallPrg SET progress=?3,next=?4 WHERE crn=?1 and `k`=?2',
        arguments: [crn, k, progress, _dateConverter.encode(next)]);
  }

  @override
  Future<void> setPrg4Sop(
    String crn,
    String k,
    int progress,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE SegmentOverallPrg SET progress=?3 WHERE crn=?1 and `k`=?2',
        arguments: [crn, k, progress]);
  }

  @override
  Future<SegmentOverallPrg?> getSegmentOverallPrg(
    String crn,
    String k,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM SegmentOverallPrg WHERE crn=?1 and `k`=?2',
        mapper: (Map<String, Object?> row) => SegmentOverallPrg(
            row['crn'] as String,
            row['k'] as String,
            _dateConverter.decode(row['next'] as int),
            row['progress'] as int),
        arguments: [crn, k]);
  }

  @override
  Future<List<SegmentOverallPrg>> getAllSegmentOverallPrg(String crn) async {
    return _queryAdapter.queryList(
        'SELECT * FROM SegmentOverallPrg WHERE crn=?1 order by next desc',
        mapper: (Map<String, Object?> row) => SegmentOverallPrg(
            row['crn'] as String,
            row['k'] as String,
            _dateConverter.decode(row['next'] as int),
            row['progress'] as int),
        arguments: [crn]);
  }

  @override
  Future<List<SegmentReview>> getAllSegmentReview(String crn) async {
    return _queryAdapter.queryList(
        'SELECT * FROM SegmentReview WHERE crn=?1 order by createDate desc',
        mapper: (Map<String, Object?> row) => SegmentReview(
            row['crn'] as String,
            _dateConverter.decode(row['createDate'] as int),
            row['k'] as String,
            row['count'] as int),
        arguments: [crn]);
  }

  @override
  Future<void> setSegmentReviewCount(
    String crn,
    List<Date> createDate,
    String k,
    int count,
  ) async {
    const offset = 4;
    final _sqliteVariablesForCreateDate =
        Iterable<String>.generate(createDate.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'UPDATE SegmentReview SET count=?3 WHERE crn=?1 and createDate in (' +
            _sqliteVariablesForCreateDate +
            ') and `k`=?2',
        arguments: [
          crn,
          k,
          count,
          ...createDate.map((element) => _dateConverter.encode(element))
        ]);
  }

  @override
  Future<SegmentContentInDb?> getSegmentContent(
    String crn,
    String k,
  ) async {
    return _queryAdapter.query(
        'SELECT Segment.crn,Segment.`k` `k`,indexDoc.id indexDocId,mediaDoc.id mediaDocId,Segment.lessonIndex lessonIndex,Segment.segmentIndex segmentIndex,Segment.sort sort,indexDoc.url indexDocUrl,indexDoc.path indexDocPath,mediaDoc.path mediaDocPath FROM Segment JOIN Doc indexDoc ON indexDoc.id=Segment.indexDocId JOIN Doc mediaDoc ON mediaDoc.id=Segment.mediaDocId WHERE Segment.crn=?1 and Segment.`k`=?2',
        mapper: (Map<String, Object?> row) => SegmentContentInDb(row['crn'] as String, row['k'] as String, row['indexDocId'] as int, row['mediaDocId'] as int, row['lessonIndex'] as int, row['segmentIndex'] as int, row['sort'] as int, row['indexDocUrl'] as String, row['indexDocPath'] as String, row['mediaDocPath'] as String),
        arguments: [crn, k]);
  }

  @override
  Future<void> insertKv(CrKv kv) async {
    await _crKvInsertionAdapter.insert(kv, OnConflictStrategy.ignore);
  }

  @override
  Future<void> insertSegmentCurrentPrg(List<SegmentCurrentPrg> entities) async {
    await _segmentCurrentPrgInsertionAdapter.insertList(
        entities, OnConflictStrategy.fail);
  }

  @override
  Future<void> insertSegmentTodayReview(List<SegmentTodayReview> review) async {
    await _segmentTodayReviewInsertionAdapter.insertList(
        review, OnConflictStrategy.fail);
  }

  @override
  Future<void> insertSegmentReview(List<SegmentReview> review) async {
    await _segmentReviewInsertionAdapter.insertList(
        review, OnConflictStrategy.fail);
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
  Future<void> deleteKv(CrKv kv) async {
    await _crKvDeletionAdapter.delete(kv);
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
  Future<List<SegmentCurrentPrg>> initToday(
      Map<String, List<SegmentTodayReview>>? forReview) async {
    if (database is sqflite.Transaction) {
      return super.initToday(forReview);
    } else {
      return (database as sqflite.Database)
          .transaction<List<SegmentCurrentPrg>>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        return transactionDatabase.scheduleDao.initToday(forReview);
      });
    }
  }

  @override
  Future<void> error(
    SegmentCurrentPrg scheduleCurrent,
    List<SegmentTodayReview> reviews,
  ) async {
    if (database is sqflite.Transaction) {
      await super.error(scheduleCurrent, reviews);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.scheduleDao.error(scheduleCurrent, reviews);
      });
    }
  }

  @override
  Future<void> right(
    SegmentCurrentPrg segmentTodayPrg,
    List<SegmentTodayReview> reviews,
  ) async {
    if (database is sqflite.Transaction) {
      await super.right(segmentTodayPrg, reviews);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.scheduleDao.right(segmentTodayPrg, reviews);
      });
    }
  }

  @override
  Future<List<String>> tryClear(bool learnOrReview) async {
    if (database is sqflite.Transaction) {
      return super.tryClear(learnOrReview);
    } else {
      return (database as sqflite.Database)
          .transaction<List<String>>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        return transactionDatabase.scheduleDao.tryClear(learnOrReview);
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
final _kConverter = KConverter();
final _crKConverter = CrKConverter();
final _dateTimeConverter = DateTimeConverter();
final _dateConverter = DateConverter();
