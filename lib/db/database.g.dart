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
            'CREATE TABLE IF NOT EXISTS `Kv` (`g` TEXT NOT NULL, `k` TEXT NOT NULL, `value` TEXT NOT NULL, PRIMARY KEY (`g`, `k`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Doc` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `url` TEXT NOT NULL, `path` TEXT NOT NULL, `count` INTEGER NOT NULL, `total` INTEGER NOT NULL, `msg` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ContentIndex` (`g` TEXT NOT NULL, `url` TEXT NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`g`, `url`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Segment` (`g` TEXT NOT NULL, `k` TEXT NOT NULL, `indexDocId` INTEGER NOT NULL, `mediaDocId` INTEGER NOT NULL, `lessonIndex` INTEGER NOT NULL, `segmentIndex` INTEGER NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`g`, `k`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentOverallPrg` (`g` TEXT NOT NULL, `k` TEXT NOT NULL, `next` INTEGER NOT NULL, `progress` INTEGER NOT NULL, PRIMARY KEY (`g`, `k`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentReview` (`g` TEXT NOT NULL, `createDate` INTEGER NOT NULL, `k` TEXT NOT NULL, `count` INTEGER NOT NULL, PRIMARY KEY (`g`, `createDate`, `k`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentTodayReview` (`g` TEXT NOT NULL, `createDate` INTEGER NOT NULL, `k` TEXT NOT NULL, `count` INTEGER NOT NULL, `finish` INTEGER NOT NULL, PRIMARY KEY (`g`, `createDate`, `k`, `count`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentCurrentPrg` (`g` TEXT NOT NULL, `k` TEXT NOT NULL, `learnOrReview` INTEGER NOT NULL, `sort` INTEGER NOT NULL, `progress` INTEGER NOT NULL, `viewTime` INTEGER NOT NULL, PRIMARY KEY (`g`, `k`, `learnOrReview`))');
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
            (Kv item) => <String, Object?>{
                  'g': item.g,
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
        mapper: (Map<String, Object?> row) => Kv(
            _kConverter.decode(row['k'] as String), row['value'] as String,
            g: row['g'] as String),
        arguments: [...k.map((element) => _kConverter.encode(element))]);
  }

  @override
  Future<Kv?> one(K k) async {
    return _queryAdapter.query('SELECT * FROM Kv where `k`=?1',
        mapper: (Map<String, Object?> row) => Kv(
            _kConverter.decode(row['k'] as String), row['value'] as String,
            g: row['g'] as String),
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

class _$ContentIndexDao extends ContentIndexDao {
  _$ContentIndexDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _contentIndexInsertionAdapter = InsertionAdapter(
            database,
            'ContentIndex',
            (ContentIndex item) => <String, Object?>{
                  'g': item.g,
                  'url': item.url,
                  'sort': item.sort
                }),
        _contentIndexDeletionAdapter = DeletionAdapter(
            database,
            'ContentIndex',
            ['g', 'url'],
            (ContentIndex item) => <String, Object?>{
                  'g': item.g,
                  'url': item.url,
                  'sort': item.sort
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ContentIndex> _contentIndexInsertionAdapter;

  final DeletionAdapter<ContentIndex> _contentIndexDeletionAdapter;

  @override
  Future<List<ContentIndex>> findContentIndex() async {
    return _queryAdapter.queryList('SELECT * FROM ContentIndex order by sort',
        mapper: (Map<String, Object?> row) => ContentIndex(
            row['url'] as String, row['sort'] as int,
            g: row['g'] as String));
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
        _kvInsertionAdapter = InsertionAdapter(
            database,
            'Kv',
            (Kv item) => <String, Object?>{
                  'g': item.g,
                  'k': _kConverter.encode(item.k),
                  'value': item.value
                }),
        _segmentCurrentPrgInsertionAdapter = InsertionAdapter(
            database,
            'SegmentCurrentPrg',
            (SegmentCurrentPrg item) => <String, Object?>{
                  'g': item.g,
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
                  'g': item.g,
                  'createDate': _dateConverter.encode(item.createDate),
                  'k': item.k,
                  'count': item.count,
                  'finish': item.finish ? 1 : 0
                }),
        _segmentReviewInsertionAdapter = InsertionAdapter(
            database,
            'SegmentReview',
            (SegmentReview item) => <String, Object?>{
                  'g': item.g,
                  'createDate': _dateConverter.encode(item.createDate),
                  'k': item.k,
                  'count': item.count
                }),
        _segmentInsertionAdapter = InsertionAdapter(
            database,
            'Segment',
            (Segment item) => <String, Object?>{
                  'g': item.g,
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
                  'g': item.g,
                  'k': item.k,
                  'next': _dateConverter.encode(item.next),
                  'progress': item.progress
                }),
        _contentIndexDeletionAdapter = DeletionAdapter(
            database,
            'ContentIndex',
            ['g', 'url'],
            (ContentIndex item) => <String, Object?>{
                  'g': item.g,
                  'url': item.url,
                  'sort': item.sort
                }),
        _segmentDeletionAdapter = DeletionAdapter(
            database,
            'Segment',
            ['g', 'k'],
            (Segment item) => <String, Object?>{
                  'g': item.g,
                  'k': item.k,
                  'indexDocId': item.indexDocId,
                  'mediaDocId': item.mediaDocId,
                  'lessonIndex': item.lessonIndex,
                  'segmentIndex': item.segmentIndex,
                  'sort': item.sort
                }),
        _kvDeletionAdapter = DeletionAdapter(
            database,
            'Kv',
            ['g', 'k'],
            (Kv item) => <String, Object?>{
                  'g': item.g,
                  'k': _kConverter.encode(item.k),
                  'value': item.value
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Kv> _kvInsertionAdapter;

  final InsertionAdapter<SegmentCurrentPrg> _segmentCurrentPrgInsertionAdapter;

  final InsertionAdapter<SegmentTodayReview>
      _segmentTodayReviewInsertionAdapter;

  final InsertionAdapter<SegmentReview> _segmentReviewInsertionAdapter;

  final InsertionAdapter<Segment> _segmentInsertionAdapter;

  final InsertionAdapter<SegmentOverallPrg> _segmentOverallPrgInsertionAdapter;

  final DeletionAdapter<ContentIndex> _contentIndexDeletionAdapter;

  final DeletionAdapter<Segment> _segmentDeletionAdapter;

  final DeletionAdapter<Kv> _kvDeletionAdapter;

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
  Future<int?> totalSegmentCurrentPrg(bool learnOrReview) async {
    return _queryAdapter.query(
        'SELECT count(1) FROM SegmentCurrentPrg where learnOrReview=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [learnOrReview ? 1 : 0]);
  }

  @override
  Future<List<SegmentCurrentPrg>> findAllSegmentCurrentPrg() async {
    return _queryAdapter.queryList('SELECT * FROM SegmentCurrentPrg',
        mapper: (Map<String, Object?> row) => SegmentCurrentPrg(
            row['k'] as String,
            (row['learnOrReview'] as int) != 0,
            row['sort'] as int,
            row['progress'] as int,
            _dateTimeConverter.decode(row['viewTime'] as int),
            g: row['g'] as String));
  }

  @override
  Future<int?> value(K k) async {
    return _queryAdapter.query(
        'SELECT CAST(value as INTEGER) FROM Kv WHERE `k`=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [_kConverter.encode(k)]);
  }

  @override
  Future<SegmentCurrentPrg?> findOneSegmentCurrentPrg(
      bool learnOrReview) async {
    return _queryAdapter.query(
        'SELECT * FROM SegmentCurrentPrg where learnOrReview=?1 limit 1',
        mapper: (Map<String, Object?> row) => SegmentCurrentPrg(
            row['k'] as String,
            (row['learnOrReview'] as int) != 0,
            row['sort'] as int,
            row['progress'] as int,
            _dateTimeConverter.decode(row['viewTime'] as int),
            g: row['g'] as String),
        arguments: [learnOrReview ? 1 : 0]);
  }

  @override
  Future<void> deleteSegmentCurrentPrg() async {
    await _queryAdapter.queryNoReturn('DELETE FROM SegmentCurrentPrg');
  }

  @override
  Future<List<SegmentCurrentPrg>> findSegmentCurrentPrg(
    bool learnOrReview,
    int maxProgress,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM SegmentCurrentPrg where learnOrReview=?1 and progress<?2 order by viewTime,sort asc',
        mapper: (Map<String, Object?> row) => SegmentCurrentPrg(row['k'] as String, (row['learnOrReview'] as int) != 0, row['sort'] as int, row['progress'] as int, _dateTimeConverter.decode(row['viewTime'] as int), g: row['g'] as String),
        arguments: [learnOrReview ? 1 : 0, maxProgress]);
  }

  @override
  Future<List<SegmentCurrentPrg>> findSegmentCurrentPrgWithReview(
    bool learnOrReview,
    int reviewCount,
  ) async {
    return _queryAdapter.queryList(
        'SELECT SegmentCurrentPrg.* FROM SegmentCurrentPrg JOIN (SELECT `k`  ,max(SegmentTodayReview.finish) finish  FROM SegmentTodayReview  WHERE SegmentTodayReview.count=?2  group by SegmentTodayReview.k ) SegmentReviewKey ON SegmentReviewKey.`k` = SegmentCurrentPrg.`k` AND SegmentReviewKey.finish=0 where learnOrReview=?1 order by viewTime,sort asc',
        mapper: (Map<String, Object?> row) => SegmentCurrentPrg(row['k'] as String, (row['learnOrReview'] as int) != 0, row['sort'] as int, row['progress'] as int, _dateTimeConverter.decode(row['viewTime'] as int), g: row['g'] as String),
        arguments: [learnOrReview ? 1 : 0, reviewCount]);
  }

  @override
  Future<void> setSegmentCurrentPrg(
    String k,
    bool learnOrReview,
    int progress,
    DateTime viewTime,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE SegmentCurrentPrg SET progress=?3,viewTime=?4 WHERE `k`=?1 and learnOrReview=?2',
        arguments: [
          k,
          learnOrReview ? 1 : 0,
          progress,
          _dateTimeConverter.encode(viewTime)
        ]);
  }

  @override
  Future<int?> findLearnedCount(Date now) async {
    return _queryAdapter.query(
        'SELECT count(1) FROM SegmentReview JOIN SegmentOverallPrg ON SegmentOverallPrg.`k` = SegmentReview.`k` JOIN Segment ON Segment.`k` = SegmentReview.`k` WHERE SegmentReview.createDate=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [_dateConverter.encode(now)]);
  }

  @override
  Future<List<SegmentOverallPrg>> findLearned(Date now) async {
    return _queryAdapter.queryList(
        'SELECT SegmentOverallPrg.* FROM SegmentReview JOIN SegmentOverallPrg ON SegmentOverallPrg.`k` = SegmentReview.`k` JOIN Segment ON Segment.`k` = SegmentReview.`k` WHERE SegmentReview.createDate=?1',
        mapper: (Map<String, Object?> row) => SegmentOverallPrg(row['k'] as String, _dateConverter.decode(row['next'] as int), row['progress'] as int, g: row['g'] as String),
        arguments: [_dateConverter.encode(now)]);
  }

  @override
  Future<void> deleteSegmentTodayReview() async {
    await _queryAdapter.queryNoReturn('DELETE FROM SegmentTodayReview');
  }

  @override
  Future<List<String>> todayFinishReviewed(
    Date now,
    int count,
  ) async {
    return _queryAdapter.queryList(
        'SELECT SegmentReview.k FROM SegmentTodayReview JOIN SegmentReview ON SegmentReview.createDate = SegmentTodayReview.createDate  ANd SegmentReview.`k` = SegmentTodayReview.`k` JOIN Segment ON Segment.`k` = SegmentReview.`k` WHERE SegmentTodayReview.createDate=?1 AND SegmentTodayReview.finish=true AND SegmentTodayReview.count=?2',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [_dateConverter.encode(now), count]);
  }

  @override
  Future<SegmentTodayReview?> findTodayReviewUnfinished() async {
    return _queryAdapter.query(
        'SELECT * FROM SegmentTodayReview WHERE SegmentTodayReview.finish=false limit 1',
        mapper: (Map<String, Object?> row) => SegmentTodayReview(
            _dateConverter.decode(row['createDate'] as int),
            row['k'] as String,
            row['count'] as int,
            (row['finish'] as int) != 0,
            g: row['g'] as String));
  }

  @override
  Future<void> setSegmentTodayReviewFinish(
    List<Date> createDate,
    String k,
  ) async {
    const offset = 2;
    final _sqliteVariablesForCreateDate =
        Iterable<String>.generate(createDate.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'UPDATE SegmentTodayReview SET finish=1 WHERE createDate in (' +
            _sqliteVariablesForCreateDate +
            ') and `k`=?1',
        arguments: [
          k,
          ...createDate.map((element) => _dateConverter.encode(element))
        ]);
  }

  @override
  Future<int?> findReviewedMinCreateDate(
    int reviewCount,
    Date now,
  ) async {
    return _queryAdapter.query(
        'SELECT ifnull(min(createDate),-1) FROM SegmentReview JOIN Segment ON Segment.`k` = SegmentReview.`k` WHERE SegmentReview.count=?1 and SegmentReview.createDate<=?2 order by createDate',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [reviewCount, _dateConverter.encode(now)]);
  }

  @override
  Future<List<SegmentReviewContentInDb>> shouldTodayReview(
    int reviewCount,
    Date startDate,
    Date endDate,
  ) async {
    return _queryAdapter.queryList(
        'SELECT Segment.k,Segment.sort,SegmentReviewKey.createDate reviewCreateDate,SegmentReviewKey.count reviewCount FROM Segment JOIN (SELECT `k`  ,group_concat(createDate) createDate  ,min(SegmentReview.count) count  FROM SegmentReview  WHERE SegmentReview.count=?1  and SegmentReview.createDate>=?2  and SegmentReview.createDate<=?3  group by SegmentReview.k) SegmentReviewKey on SegmentReviewKey.`k`=Segment.`k` order by sort',
        mapper: (Map<String, Object?> row) => SegmentReviewContentInDb(row['k'] as String, row['sort'] as int, row['reviewCount'] as int, row['reviewCreateDate'] as String),
        arguments: [
          reviewCount,
          _dateConverter.encode(startDate),
          _dateConverter.encode(endDate)
        ]);
  }

  @override
  Future<List<SegmentReviewContentInDb>> scheduleLearnToday(
    int limit,
    Date now,
  ) async {
    return _queryAdapter.queryList(
        'SELECT Segment.k,Segment.sort,\'0\' reviewCreateDate,0 reviewCount FROM SegmentOverallPrg JOIN Segment ON Segment.`k` = SegmentOverallPrg.`k` where SegmentOverallPrg.next<=?2 order by SegmentOverallPrg.progress limit ?1',
        mapper: (Map<String, Object?> row) => SegmentReviewContentInDb(row['k'] as String, row['sort'] as int, row['reviewCount'] as int, row['reviewCreateDate'] as String),
        arguments: [limit, _dateConverter.encode(now)]);
  }

  @override
  Future<int?> findSegmentOverallPrgCount(
    int limit,
    DateTime now,
  ) async {
    return _queryAdapter.query(
        'SELECT count(1) FROM SegmentOverallPrg JOIN Segment ON Segment.`k` = SegmentOverallPrg.`k` where next<?2 order by progress,sort limit ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [limit, _dateTimeConverter.encode(now)]);
  }

  @override
  Future<void> setSegmentOverallPrg(
    String k,
    int progress,
    Date next,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE SegmentOverallPrg SET progress=?2,next=?3 WHERE `k`=?1',
        arguments: [k, progress, _dateConverter.encode(next)]);
  }

  @override
  Future<SegmentOverallPrg?> getSegmentOverallPrg(String k) async {
    return _queryAdapter.query('SELECT * FROM SegmentOverallPrg WHERE `k`=?1',
        mapper: (Map<String, Object?> row) => SegmentOverallPrg(
            row['k'] as String,
            _dateConverter.decode(row['next'] as int),
            row['progress'] as int,
            g: row['g'] as String),
        arguments: [k]);
  }

  @override
  Future<void> setSegmentReviewCount(
    List<Date> createDate,
    String k,
    int count,
  ) async {
    const offset = 3;
    final _sqliteVariablesForCreateDate =
        Iterable<String>.generate(createDate.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'UPDATE SegmentReview SET count=?2 WHERE createDate in (' +
            _sqliteVariablesForCreateDate +
            ') and `k`=?1',
        arguments: [
          k,
          count,
          ...createDate.map((element) => _dateConverter.encode(element))
        ]);
  }

  @override
  Future<SegmentContentInDb?> getSegmentContent(String k) async {
    return _queryAdapter.query(
        'SELECT Segment.`k` `k`,indexDoc.id indexDocId,mediaDoc.id mediaDocId,Segment.lessonIndex lessonIndex,Segment.segmentIndex segmentIndex,Segment.sort sort,indexDoc.url indexDocUrl,indexDoc.path indexDocPath,mediaDoc.path mediaDocPath FROM Segment JOIN Doc indexDoc ON indexDoc.id=Segment.indexDocId JOIN Doc mediaDoc ON mediaDoc.id=Segment.mediaDocId WHERE Segment.`k`=?1',
        mapper: (Map<String, Object?> row) => SegmentContentInDb(row['k'] as String, row['indexDocId'] as int, row['mediaDocId'] as int, row['lessonIndex'] as int, row['segmentIndex'] as int, row['sort'] as int, row['indexDocUrl'] as String, row['indexDocPath'] as String, row['mediaDocPath'] as String),
        arguments: [k]);
  }

  @override
  Future<List<String>> findKeyByUrl(String indexUrl) async {
    return _queryAdapter.queryList(
        'SELECT `k` FROM Schedule WHERE indexUrl = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [indexUrl]);
  }

  @override
  Future<void> insertKv(Kv kv) async {
    await _kvInsertionAdapter.insert(kv, OnConflictStrategy.ignore);
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
  Future<void> deleteKv(Kv kv) async {
    await _kvDeletionAdapter.delete(kv);
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
  Future<List<String>> tryClear() async {
    if (database is sqflite.Transaction) {
      return super.tryClear();
    } else {
      return (database as sqflite.Database)
          .transaction<List<String>>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        return transactionDatabase.scheduleDao.tryClear();
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
final _dateTimeConverter = DateTimeConverter();
final _dateConverter = DateConverter();
