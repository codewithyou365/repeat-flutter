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

  VideoAttributeDao? _videoAttributeDaoInstance;

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
      version: 3,
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
            'CREATE TABLE IF NOT EXISTS `Doc` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `url` TEXT NOT NULL, `path` TEXT NOT NULL, `count` INTEGER NOT NULL, `total` INTEGER NOT NULL, `msg` TEXT NOT NULL, `hash` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `VideoAttribute` (`path` TEXT NOT NULL, `maskRatio` REAL NOT NULL, PRIMARY KEY (`path`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Classroom` (`name` TEXT NOT NULL, `arg` TEXT NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`name`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ContentIndex` (`crn` TEXT NOT NULL, `url` TEXT NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`crn`, `url`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `CrKv` (`crn` TEXT NOT NULL, `k` TEXT NOT NULL, `value` TEXT NOT NULL, PRIMARY KEY (`crn`, `k`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Segment` (`segmentKeyId` INTEGER NOT NULL, `indexDocId` INTEGER NOT NULL, `mediaDocId` INTEGER NOT NULL, `lessonIndex` INTEGER NOT NULL, `segmentIndex` INTEGER NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`segmentKeyId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentKey` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `crn` TEXT NOT NULL, `k` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentOverallPrg` (`segmentKeyId` INTEGER NOT NULL, `next` INTEGER NOT NULL, `progress` INTEGER NOT NULL, PRIMARY KEY (`segmentKeyId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentReview` (`createDate` INTEGER NOT NULL, `segmentKeyId` INTEGER NOT NULL, `count` INTEGER NOT NULL, PRIMARY KEY (`createDate`, `segmentKeyId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentTodayPrg` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `segmentKeyId` INTEGER NOT NULL, `type` INTEGER NOT NULL, `sort` INTEGER NOT NULL, `progress` INTEGER NOT NULL, `viewTime` INTEGER NOT NULL, `reviewCount` INTEGER NOT NULL, `reviewCreateDate` INTEGER NOT NULL, `finish` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Id99999` (`id` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Lock` (`id` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database
            .execute('CREATE UNIQUE INDEX `index_Doc_url` ON `Doc` (`url`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Classroom_sort` ON `Classroom` (`sort`)');
        await database.execute(
            'CREATE INDEX `index_ContentIndex_sort` ON `ContentIndex` (`sort`)');
        await database
            .execute('CREATE INDEX `index_Segment_sort` ON `Segment` (`sort`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_SegmentKey_crn_k` ON `SegmentKey` (`crn`, `k`)');
        await database.execute(
            'CREATE INDEX `index_SegmentOverallPrg_next_progress` ON `SegmentOverallPrg` (`next`, `progress`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_SegmentTodayPrg_segmentKeyId_type` ON `SegmentTodayPrg` (`segmentKeyId`, `type`)');
        await database.execute(
            'CREATE INDEX `index_SegmentTodayPrg_sort` ON `SegmentTodayPrg` (`sort`)');

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
  VideoAttributeDao get videoAttributeDao {
    return _videoAttributeDaoInstance ??=
        _$VideoAttributeDao(database, changeListener);
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
                  'msg': item.msg,
                  'hash': item.hash
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
            row['url'] as String, row['path'] as String, row['hash'] as String,
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
    String hash,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE OR ABORT Doc SET count=total,path=?2,hash=?3 WHERE id = ?1',
        arguments: [id, path, hash]);
  }

  @override
  Future<void> insertDoc(Doc data) async {
    await _docInsertionAdapter.insert(data, OnConflictStrategy.replace);
  }

  @override
  Future<Doc> insert(String url) async {
    if (database is sqflite.Transaction) {
      return super.insert(url);
    } else {
      return (database as sqflite.Database)
          .transaction<Doc>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        return transactionDatabase.docDao.insert(url);
      });
    }
  }
}

class _$VideoAttributeDao extends VideoAttributeDao {
  _$VideoAttributeDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _videoAttributeInsertionAdapter = InsertionAdapter(
            database,
            'VideoAttribute',
            (VideoAttribute item) => <String, Object?>{
                  'path': item.path,
                  'maskRatio': item.maskRatio
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<VideoAttribute> _videoAttributeInsertionAdapter;

  @override
  Future<VideoAttribute?> one(String path) async {
    return _queryAdapter.query('SELECT * FROM VideoAttribute WHERE path = ?1',
        mapper: (Map<String, Object?> row) =>
            VideoAttribute(row['path'] as String, row['maskRatio'] as double),
        arguments: [path]);
  }

  @override
  Future<void> insertVideoAttribute(VideoAttribute entity) async {
    await _videoAttributeInsertionAdapter.insert(
        entity, OnConflictStrategy.replace);
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
    await _classroomInsertionAdapter.insert(entity, OnConflictStrategy.ignore);
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
        'SELECT Id99999.id FROM Id99999 LEFT JOIN (  select sort from ContentIndex where ContentIndex.crn=?1 ) ContentIndex ON ContentIndex.sort = Id99999.id WHERE ContentIndex.sort IS NULL limit 1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [crn]);
  }

  @override
  Future<int?> count(
    String crn,
    String url,
  ) async {
    return _queryAdapter.query(
        'SELECT count(1) FROM ContentIndex where crn=?1 and url=?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [crn, url]);
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
        _segmentTodayPrgInsertionAdapter = InsertionAdapter(
            database,
            'SegmentTodayPrg',
            (SegmentTodayPrg item) => <String, Object?>{
                  'id': item.id,
                  'segmentKeyId': item.segmentKeyId,
                  'type': item.type,
                  'sort': item.sort,
                  'progress': item.progress,
                  'viewTime': _dateTimeConverter.encode(item.viewTime),
                  'reviewCount': item.reviewCount,
                  'reviewCreateDate':
                      _dateConverter.encode(item.reviewCreateDate),
                  'finish': item.finish ? 1 : 0
                }),
        _segmentReviewInsertionAdapter = InsertionAdapter(
            database,
            'SegmentReview',
            (SegmentReview item) => <String, Object?>{
                  'createDate': _dateConverter.encode(item.createDate),
                  'segmentKeyId': item.segmentKeyId,
                  'count': item.count
                }),
        _segmentKeyInsertionAdapter = InsertionAdapter(
            database,
            'SegmentKey',
            (SegmentKey item) =>
                <String, Object?>{'id': item.id, 'crn': item.crn, 'k': item.k}),
        _segmentInsertionAdapter = InsertionAdapter(
            database,
            'Segment',
            (Segment item) => <String, Object?>{
                  'segmentKeyId': item.segmentKeyId,
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
                  'segmentKeyId': item.segmentKeyId,
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
            ['segmentKeyId'],
            (Segment item) => <String, Object?>{
                  'segmentKeyId': item.segmentKeyId,
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

  final InsertionAdapter<SegmentTodayPrg> _segmentTodayPrgInsertionAdapter;

  final InsertionAdapter<SegmentReview> _segmentReviewInsertionAdapter;

  final InsertionAdapter<SegmentKey> _segmentKeyInsertionAdapter;

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
  Future<List<int>> getSegmentKeyId(
    String crn,
    int indexDocId,
  ) async {
    return _queryAdapter.queryList(
        'SELECT SegmentKey.id FROM SegmentKey JOIN Segment ON Segment.segmentKeyId=SegmentKey.id  AND Segment.indexDocId=?2 WHERE SegmentKey.crn=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [crn, indexDocId]);
  }

  @override
  Future<List<int>> getSegmentKeyIdByCrn(String crn) async {
    return _queryAdapter.queryList(
        'SELECT SegmentKey.id FROM SegmentKey WHERE SegmentKey.crn=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [crn]);
  }

  @override
  Future<int?> intKv(
    String crn,
    CrK k,
  ) async {
    return _queryAdapter.query(
        'SELECT CAST(value as INTEGER) FROM CrKv WHERE crn=?1 and k=?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [crn, _crKConverter.encode(k)]);
  }

  @override
  Future<String?> stringKv(
    String crn,
    CrK k,
  ) async {
    return _queryAdapter.query('SELECT value FROM CrKv WHERE crn=?1 and k=?2',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [crn, _crKConverter.encode(k)]);
  }

  @override
  Future<void> updateKv(
    String crn,
    CrK k,
    String value,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE CrKv SET value=?3 WHERE crn=?1 and k=?2',
        arguments: [crn, _crKConverter.encode(k), value]);
  }

  @override
  Future<void> deleteSegmentTodayPrgByIds(List<int> ids) async {
    const offset = 1;
    final _sqliteVariablesForIds =
        Iterable<String>.generate(ids.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'DELETE FROM SegmentTodayPrg where segmentKeyId in (' +
            _sqliteVariablesForIds +
            ')',
        arguments: [...ids]);
  }

  @override
  Future<List<SegmentTodayPrgWithKey>> findSegmentTodayPrg(String crn) async {
    return _queryAdapter.queryList(
        'SELECT SegmentTodayPrg.*,SegmentKey.k FROM SegmentTodayPrg JOIN SegmentKey on SegmentKey.id=SegmentTodayPrg.segmentKeyId AND SegmentKey.crn=?1 order by id asc',
        mapper: (Map<String, Object?> row) => SegmentTodayPrgWithKey(row['segmentKeyId'] as int, row['type'] as int, row['sort'] as int, row['progress'] as int, _dateTimeConverter.decode(row['viewTime'] as int), row['reviewCount'] as int, _dateConverter.decode(row['reviewCreateDate'] as int), (row['finish'] as int) != 0, row['k'] as String),
        arguments: [crn]);
  }

  @override
  Future<void> setSegmentTodayPrg(
    int segmentKeyId,
    int type,
    int progress,
    DateTime viewTime,
    bool finish,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE SegmentTodayPrg SET progress=?3,viewTime=?4,finish=?5 WHERE segmentKeyId=?1 and type=?2',
        arguments: [
          segmentKeyId,
          type,
          progress,
          _dateTimeConverter.encode(viewTime),
          finish ? 1 : 0
        ]);
  }

  @override
  Future<int?> findReviewedMinCreateDate(
    String crn,
    int reviewCount,
    Date now,
  ) async {
    return _queryAdapter.query(
        'SELECT ifnull(min(SegmentReview.createDate),-1) FROM SegmentReview JOIN Segment ON Segment.segmentKeyId=SegmentReview.segmentKeyId JOIN SegmentKey on SegmentKey.id=SegmentReview.segmentKeyId AND SegmentKey.crn=?1 WHERE SegmentReview.count=?2 and SegmentReview.createDate<=?3 order by createDate',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [crn, reviewCount, _dateConverter.encode(now)]);
  }

  @override
  Future<List<SegmentTodayPrgWithKey>> scheduleReview(
    String crn,
    int reviewCount,
    Date startDate,
  ) async {
    return _queryAdapter.queryList(
        'SELECT SegmentReview.segmentKeyId,0 type,Segment.sort,0 progress,0 viewTime,SegmentReview.count reviewCount,SegmentReview.createDate reviewCreateDate,0 finish,SegmentKey.k FROM SegmentReview JOIN SegmentKey on SegmentKey.id=SegmentReview.segmentKeyId AND SegmentKey.crn=?1 JOIN Segment ON Segment.segmentKeyId=SegmentReview.segmentKeyId WHERE SegmentReview.count=?2 AND SegmentReview.createDate=?3 ORDER BY Segment.sort',
        mapper: (Map<String, Object?> row) => SegmentTodayPrgWithKey(row['segmentKeyId'] as int, row['type'] as int, row['sort'] as int, row['progress'] as int, _dateTimeConverter.decode(row['viewTime'] as int), row['reviewCount'] as int, _dateConverter.decode(row['reviewCreateDate'] as int), (row['finish'] as int) != 0, row['k'] as String),
        arguments: [crn, reviewCount, _dateConverter.encode(startDate)]);
  }

  @override
  Future<List<SegmentTodayPrgWithKey>> scheduleLearn(
    String crn,
    int minProgress,
    Date now,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ( SELECT SegmentOverallPrg.segmentKeyId,0 type,Segment.sort,SegmentOverallPrg.progress progress,0 viewTime,0 reviewCount,0 reviewCreateDate,0 finish,SegmentKey.k FROM SegmentOverallPrg JOIN SegmentKey on SegmentKey.id=SegmentOverallPrg.segmentKeyId AND SegmentKey.crn=?1 JOIN Segment ON Segment.segmentKeyId=SegmentOverallPrg.segmentKeyId where SegmentOverallPrg.next<=?3 and SegmentOverallPrg.progress>=?2 order by SegmentOverallPrg.progress,Segment.sort ) Segment order by Segment.sort',
        mapper: (Map<String, Object?> row) => SegmentTodayPrgWithKey(row['segmentKeyId'] as int, row['type'] as int, row['sort'] as int, row['progress'] as int, _dateTimeConverter.decode(row['viewTime'] as int), row['reviewCount'] as int, _dateConverter.decode(row['reviewCreateDate'] as int), (row['finish'] as int) != 0, row['k'] as String),
        arguments: [crn, minProgress, _dateConverter.encode(now)]);
  }

  @override
  Future<void> setPrgAndNext4Sop(
    int segmentKeyId,
    int progress,
    Date next,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE SegmentOverallPrg SET progress=?2,next=?3 WHERE segmentKeyId=?1',
        arguments: [segmentKeyId, progress, _dateConverter.encode(next)]);
  }

  @override
  Future<void> setPrg4Sop(
    int segmentKeyId,
    int progress,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE SegmentOverallPrg SET progress=?2 WHERE segmentKeyId=?1',
        arguments: [segmentKeyId, progress]);
  }

  @override
  Future<SegmentOverallPrg?> getSegmentOverallPrg(int segmentKeyId) async {
    return _queryAdapter.query(
        'SELECT * FROM SegmentOverallPrg WHERE segmentKeyId=?1',
        mapper: (Map<String, Object?> row) => SegmentOverallPrg(
            row['segmentKeyId'] as int,
            _dateConverter.decode(row['next'] as int),
            row['progress'] as int),
        arguments: [segmentKeyId]);
  }

  @override
  Future<List<SegmentOverallPrgWithKey>> getAllSegmentOverallPrg(
      String crn) async {
    return _queryAdapter.queryList(
        'SELECT SegmentOverallPrg.*,SegmentKey.crn,SegmentKey.k FROM SegmentOverallPrg JOIN SegmentKey on SegmentKey.id=SegmentOverallPrg.segmentKeyId AND SegmentKey.crn=?1 ORDER BY SegmentOverallPrg.segmentKeyId asc',
        mapper: (Map<String, Object?> row) => SegmentOverallPrgWithKey(row['segmentKeyId'] as int, _dateConverter.decode(row['next'] as int), row['progress'] as int, row['crn'] as String, row['k'] as String),
        arguments: [crn]);
  }

  @override
  Future<List<SegmentReviewWithKey>> getAllSegmentReview(String crn) async {
    return _queryAdapter.queryList(
        'SELECT SegmentReview.*,SegmentKey.crn,SegmentKey.k FROM SegmentReview JOIN SegmentKey on SegmentKey.id=SegmentReview.segmentKeyId AND SegmentKey.crn=?1 ORDER BY createDate desc, segmentKeyId asc',
        mapper: (Map<String, Object?> row) => SegmentReviewWithKey(_dateConverter.decode(row['createDate'] as int), row['segmentKeyId'] as int, row['count'] as int, row['crn'] as String, row['k'] as String),
        arguments: [crn]);
  }

  @override
  Future<void> setSegmentReviewCount(
    Date createDate,
    int segmentKeyId,
    int count,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE SegmentReview SET count=?3 WHERE createDate=?1 and `segmentKeyId`=?2',
        arguments: [_dateConverter.encode(createDate), segmentKeyId, count]);
  }

  @override
  Future<SegmentContentInDb?> getSegmentContent(int segmentKeyId) async {
    return _queryAdapter.query(
        'SELECT Segment.segmentKeyId,IFNULL(indexDoc.id,0) indexDocId,IFNULL(mediaDoc.id,0) mediaDocId,Segment.lessonIndex lessonIndex,Segment.segmentIndex segmentIndex,Segment.sort sort,SegmentKey.crn crn,SegmentKey.k k,IFNULL(indexDoc.url,\'\') indexDocUrl,IFNULL(indexDoc.path,\'\') indexDocPath,IFNULL(mediaDoc.path,\'\') mediaDocPath FROM Segment JOIN SegmentKey segmentKey ON segmentKey.id=?1 LEFT JOIN Doc indexDoc ON indexDoc.id=Segment.indexDocId LEFT JOIN Doc mediaDoc ON mediaDoc.id=Segment.mediaDocId WHERE Segment.segmentKeyId=?1',
        mapper: (Map<String, Object?> row) => SegmentContentInDb(row['segmentKeyId'] as int, row['indexDocId'] as int, row['mediaDocId'] as int, row['lessonIndex'] as int, row['segmentIndex'] as int, row['sort'] as int, row['crn'] as String, row['k'] as String, row['indexDocUrl'] as String, row['indexDocPath'] as String, row['mediaDocPath'] as String),
        arguments: [segmentKeyId]);
  }

  @override
  Future<int?> getPrevSegmentKeyIdWithOffset(
    String crn,
    int segmentKeyId,
    int offset,
  ) async {
    return _queryAdapter.query(
        'SELECT LimitSegment.segmentKeyId FROM (SELECT Segment.sort,Segment.segmentKeyId  FROM Segment  JOIN SegmentKey ON SegmentKey.id = Segment.segmentKeyId AND SegmentKey.crn=?1  WHERE Segment.sort<(SELECT Segment.sort FROM Segment WHERE Segment.segmentKeyId=?2)  ORDER BY Segment.sort desc  LIMIT ?3) LimitSegment  ORDER BY LimitSegment.sort LIMIT 1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [crn, segmentKeyId, offset]);
  }

  @override
  Future<int?> getNextSegmentKeyIdWithOffset(
    String crn,
    int segmentKeyId,
    int offset,
  ) async {
    return _queryAdapter.query(
        'SELECT LimitSegment.segmentKeyId FROM (SELECT Segment.sort,Segment.segmentKeyId  FROM Segment  JOIN SegmentKey ON SegmentKey.id = Segment.segmentKeyId AND SegmentKey.crn=?1  WHERE Segment.sort>(SELECT Segment.sort FROM Segment WHERE Segment.segmentKeyId=?2)  ORDER BY Segment.sort  LIMIT ?3) LimitSegment  ORDER BY LimitSegment.sort desc LIMIT 1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [crn, segmentKeyId, offset]);
  }

  @override
  Future<List<SegmentKey>> getSegmentKey(
    String crn,
    List<String> keys,
  ) async {
    const offset = 2;
    final _sqliteVariablesForKeys =
        Iterable<String>.generate(keys.length, (i) => '?${i + offset}')
            .join(',');
    return _queryAdapter.queryList(
        'SELECT SegmentKey.* FROM SegmentKey WHERE SegmentKey.crn=?1 and SegmentKey.k in (' +
            _sqliteVariablesForKeys +
            ')',
        mapper: (Map<String, Object?> row) => SegmentKey(row['crn'] as String, row['k'] as String, id: row['id'] as int?),
        arguments: [crn, ...keys]);
  }

  @override
  Future<void> deleteSegment(int segmentKeyId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Segment WHERE segmentKeyId=?1',
        arguments: [segmentKeyId]);
  }

  @override
  Future<void> deleteSegmentKey(int segmentKeyId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM SegmentKey WHERE id=?1',
        arguments: [segmentKeyId]);
  }

  @override
  Future<void> deleteSegmentOverallPrg(int segmentKeyId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM SegmentOverallPrg WHERE segmentKeyId=?1',
        arguments: [segmentKeyId]);
  }

  @override
  Future<void> deleteSegmentReview(int segmentKeyId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM SegmentReview WHERE segmentKeyId=?1',
        arguments: [segmentKeyId]);
  }

  @override
  Future<void> deleteSegmentTodayPrg(int segmentKeyId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM SegmentTodayPrg WHERE segmentKeyId=?1',
        arguments: [segmentKeyId]);
  }

  @override
  Future<void> insertKv(CrKv kv) async {
    await _crKvInsertionAdapter.insert(kv, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertSegmentTodayPrg(List<SegmentTodayPrg> entities) async {
    await _segmentTodayPrgInsertionAdapter.insertList(
        entities, OnConflictStrategy.fail);
  }

  @override
  Future<void> insertSegmentReview(List<SegmentReview> review) async {
    await _segmentReviewInsertionAdapter.insertList(
        review, OnConflictStrategy.fail);
  }

  @override
  Future<void> insertSegmentKeys(List<SegmentKey> entities) async {
    await _segmentKeyInsertionAdapter.insertList(
        entities, OnConflictStrategy.ignore);
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
  Future<void> deleteBySegmentKeyId(int segmentKeyId) async {
    if (database is sqflite.Transaction) {
      await super.deleteBySegmentKeyId(segmentKeyId);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.scheduleDao
            .deleteBySegmentKeyId(segmentKeyId);
      });
    }
  }

  @override
  Future<void> importSegment(
    List<SegmentKey> rawSegmentKeys,
    List<Segment> segments,
    List<SegmentOverallPrg> segmentOverallPrgs,
  ) async {
    if (database is sqflite.Transaction) {
      await super.importSegment(rawSegmentKeys, segments, segmentOverallPrgs);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.scheduleDao
            .importSegment(rawSegmentKeys, segments, segmentOverallPrgs);
      });
    }
  }

  @override
  Future<void> deleteContent(
    String url,
    int indexDocId,
  ) async {
    if (database is sqflite.Transaction) {
      await super.deleteContent(url, indexDocId);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.scheduleDao.deleteContent(url, indexDocId);
      });
    }
  }

  @override
  Future<List<SegmentTodayPrgWithKey>> initToday() async {
    if (database is sqflite.Transaction) {
      return super.initToday();
    } else {
      return (database as sqflite.Database)
          .transaction<List<SegmentTodayPrgWithKey>>((transaction) async {
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
