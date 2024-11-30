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

  MaterialDao? _materialDaoInstance;

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
            'CREATE TABLE IF NOT EXISTS `Classroom` (`id` INTEGER NOT NULL, `name` TEXT NOT NULL, `sort` INTEGER NOT NULL, `hide` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Material` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `classroomId` INTEGER NOT NULL, `serial` INTEGER NOT NULL, `name` TEXT NOT NULL, `desc` TEXT NOT NULL, `docId` INTEGER NOT NULL, `sort` INTEGER NOT NULL, `hide` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `CrKv` (`classroomId` INTEGER NOT NULL, `k` TEXT NOT NULL, `value` TEXT NOT NULL, PRIMARY KEY (`classroomId`, `k`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Segment` (`segmentKeyId` INTEGER NOT NULL, `classroomId` INTEGER NOT NULL, `materialSerial` INTEGER NOT NULL, `lessonIndex` INTEGER NOT NULL, `segmentIndex` INTEGER NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`segmentKeyId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentKey` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `classroomId` INTEGER NOT NULL, `materialSerial` INTEGER NOT NULL, `lessonIndex` INTEGER NOT NULL, `segmentIndex` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentOverallPrg` (`segmentKeyId` INTEGER NOT NULL, `classroomId` INTEGER NOT NULL, `materialSerial` INTEGER NOT NULL, `next` INTEGER NOT NULL, `progress` INTEGER NOT NULL, PRIMARY KEY (`segmentKeyId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentReview` (`createDate` INTEGER NOT NULL, `segmentKeyId` INTEGER NOT NULL, `classroomId` INTEGER NOT NULL, `materialSerial` INTEGER NOT NULL, `count` INTEGER NOT NULL, PRIMARY KEY (`createDate`, `segmentKeyId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SegmentTodayPrg` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `classroomId` INTEGER NOT NULL, `materialSerial` INTEGER NOT NULL, `segmentKeyId` INTEGER NOT NULL, `type` INTEGER NOT NULL, `sort` INTEGER NOT NULL, `progress` INTEGER NOT NULL, `viewTime` INTEGER NOT NULL, `reviewCount` INTEGER NOT NULL, `reviewCreateDate` INTEGER NOT NULL, `finish` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Lock` (`id` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database
            .execute('CREATE UNIQUE INDEX `index_Doc_path` ON `Doc` (`path`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Classroom_name` ON `Classroom` (`name`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Classroom_sort` ON `Classroom` (`sort`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Material_classroomId_name` ON `Material` (`classroomId`, `name`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Material_classroomId_serial` ON `Material` (`classroomId`, `serial`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Material_classroomId_sort` ON `Material` (`classroomId`, `sort`)');
        await database.execute(
            'CREATE INDEX `index_Material_sort_id` ON `Material` (`sort`, `id`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Segment_classroomId_sort` ON `Segment` (`classroomId`, `sort`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Segment_classroomId_materialSerial_lessonIndex_segmentIndex` ON `Segment` (`classroomId`, `materialSerial`, `lessonIndex`, `segmentIndex`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_SegmentKey_classroomId_materialSerial_lessonIndex_segmentIndex` ON `SegmentKey` (`classroomId`, `materialSerial`, `lessonIndex`, `segmentIndex`)');
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
  ClassroomDao get classroomDao {
    return _classroomDaoInstance ??= _$ClassroomDao(database, changeListener);
  }

  @override
  MaterialDao get materialDao {
    return _materialDaoInstance ??= _$MaterialDao(database, changeListener);
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
  Future<Doc?> getByPath(String path) async {
    return _queryAdapter.query('SELECT * FROM Doc WHERE path=?1',
        mapper: (Map<String, Object?> row) => Doc(
            row['url'] as String, row['path'] as String, row['hash'] as String,
            id: row['id'] as int?,
            msg: row['msg'] as String,
            count: row['count'] as int,
            total: row['total'] as int),
        arguments: [path]);
  }

  @override
  Future<Doc?> getById(int id) async {
    return _queryAdapter.query('SELECT * FROM Doc WHERE id=?1',
        mapper: (Map<String, Object?> row) => Doc(
            row['url'] as String, row['path'] as String, row['hash'] as String,
            id: row['id'] as int?,
            msg: row['msg'] as String,
            count: row['count'] as int,
            total: row['total'] as int),
        arguments: [id]);
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

class _$ClassroomDao extends ClassroomDao {
  _$ClassroomDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _classroomInsertionAdapter = InsertionAdapter(
            database,
            'Classroom',
            (Classroom item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'sort': item.sort,
                  'hide': item.hide ? 1 : 0
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Classroom> _classroomInsertionAdapter;

  @override
  Future<void> forUpdate() async {
    await _queryAdapter
        .queryNoReturn('SELECT * FROM Lock where id=1 for update');
  }

  @override
  Future<List<Classroom>> getAllClassroom() async {
    return _queryAdapter.queryList(
        'SELECT * FROM Classroom WHERE hide=false ORDER BY sort',
        mapper: (Map<String, Object?> row) => Classroom(
            row['id'] as int,
            row['name'] as String,
            row['sort'] as int,
            (row['hide'] as int) != 0));
  }

  @override
  Future<int?> existById(int id) async {
    return _queryAdapter.query('SELECT ifnull(id,0) FROM Classroom WHERE id=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [id]);
  }

  @override
  Future<int?> getMaxId() async {
    return _queryAdapter.query('SELECT ifnull(max(id),0) FROM Classroom',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<int?> existBySort(int sort) async {
    return _queryAdapter.query(
        'SELECT ifnull(sort,0) FROM Classroom WHERE sort=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [sort]);
  }

  @override
  Future<int?> getMaxSort() async {
    return _queryAdapter.query('SELECT ifnull(max(sort),0) FROM Classroom',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<Classroom?> getClassroom(String name) async {
    return _queryAdapter.query('SELECT * FROM Classroom WHERE name=?1',
        mapper: (Map<String, Object?> row) => Classroom(
            row['id'] as int,
            row['name'] as String,
            row['sort'] as int,
            (row['hide'] as int) != 0),
        arguments: [name]);
  }

  @override
  Future<void> hide(int id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Classroom set hide=true WHERE Classroom.id=?1',
        arguments: [id]);
  }

  @override
  Future<void> showClassroom(int id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Classroom set hide=false WHERE Classroom.id=?1',
        arguments: [id]);
  }

  @override
  Future<void> insertClassroom(Classroom entity) async {
    await _classroomInsertionAdapter.insert(entity, OnConflictStrategy.fail);
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

class _$MaterialDao extends MaterialDao {
  _$MaterialDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _materialInsertionAdapter = InsertionAdapter(
            database,
            'Material',
            (Material item) => <String, Object?>{
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'serial': item.serial,
                  'name': item.name,
                  'desc': item.desc,
                  'docId': item.docId,
                  'sort': item.sort,
                  'hide': item.hide ? 1 : 0
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Material> _materialInsertionAdapter;

  @override
  Future<void> forUpdate() async {
    await _queryAdapter
        .queryNoReturn('SELECT * FROM Lock where id=1 for update');
  }

  @override
  Future<List<Material>> getAllMaterial(int classroomId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Material where classroomId=?1 and hide=false ORDER BY sort',
        mapper: (Map<String, Object?> row) => Material(row['classroomId'] as int, row['serial'] as int, row['name'] as String, row['desc'] as String, row['docId'] as int, row['sort'] as int, (row['hide'] as int) != 0, id: row['id'] as int?),
        arguments: [classroomId]);
  }

  @override
  Future<int?> getMaxSerial(int classroomId) async {
    return _queryAdapter.query(
        'SELECT ifnull(max(serial),0) FROM Material WHERE classroomId=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId]);
  }

  @override
  Future<int?> existBySerial(
    int classroomId,
    int serial,
  ) async {
    return _queryAdapter.query(
        'SELECT ifnull(serial,0) FROM Material WHERE classroomId=?1 and serial=?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, serial]);
  }

  @override
  Future<int?> getMaxSort(int classroomId) async {
    return _queryAdapter.query(
        'SELECT ifnull(max(sort),0) FROM Material WHERE classroomId=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId]);
  }

  @override
  Future<int?> existBySort(
    int classroomId,
    int sort,
  ) async {
    return _queryAdapter.query(
        'SELECT ifnull(sort,0) FROM Material WHERE classroomId=?1 and sort=?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, sort]);
  }

  @override
  Future<Material?> getMaterialByName(
    int classroomId,
    String name,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM Material WHERE classroomId=?1 and name=?2',
        mapper: (Map<String, Object?> row) => Material(
            row['classroomId'] as int,
            row['serial'] as int,
            row['name'] as String,
            row['desc'] as String,
            row['docId'] as int,
            row['sort'] as int,
            (row['hide'] as int) != 0,
            id: row['id'] as int?),
        arguments: [classroomId, name]);
  }

  @override
  Future<Material?> getMaterialBySerial(
    int classroomId,
    int serial,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM Material WHERE classroomId=?1 and serial=?2',
        mapper: (Map<String, Object?> row) => Material(
            row['classroomId'] as int,
            row['serial'] as int,
            row['name'] as String,
            row['desc'] as String,
            row['docId'] as int,
            row['sort'] as int,
            (row['hide'] as int) != 0,
            id: row['id'] as int?),
        arguments: [classroomId, serial]);
  }

  @override
  Future<Material?> getMaterialBySort(
    int classroomId,
    int sort,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM Material WHERE classroomId=?1 and sort=?2',
        mapper: (Map<String, Object?> row) => Material(
            row['classroomId'] as int,
            row['serial'] as int,
            row['name'] as String,
            row['desc'] as String,
            row['docId'] as int,
            row['sort'] as int,
            (row['hide'] as int) != 0,
            id: row['id'] as int?),
        arguments: [classroomId, sort]);
  }

  @override
  Future<void> hide(int id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Material set hide=true WHERE Material.id=?1',
        arguments: [id]);
  }

  @override
  Future<void> showMaterial(int id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Material set hide=false WHERE Material.id=?1',
        arguments: [id]);
  }

  @override
  Future<void> updateDocId(
    int id,
    int docId,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Material set docId=?2 WHERE Material.id=?1',
        arguments: [id, docId]);
  }

  @override
  Future<void> insertMaterial(Material entity) async {
    await _materialInsertionAdapter.insert(entity, OnConflictStrategy.fail);
  }

  @override
  Future<Material> add(String name) async {
    if (database is sqflite.Transaction) {
      return super.add(name);
    } else {
      return (database as sqflite.Database)
          .transaction<Material>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        return transactionDatabase.materialDao.add(name);
      });
    }
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
                  'classroomId': item.classroomId,
                  'k': _crKConverter.encode(item.k),
                  'value': item.value
                }),
        _segmentTodayPrgInsertionAdapter = InsertionAdapter(
            database,
            'SegmentTodayPrg',
            (SegmentTodayPrg item) => <String, Object?>{
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'materialSerial': item.materialSerial,
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
                  'classroomId': item.classroomId,
                  'materialSerial': item.materialSerial,
                  'count': item.count
                }),
        _segmentKeyInsertionAdapter = InsertionAdapter(
            database,
            'SegmentKey',
            (SegmentKey item) => <String, Object?>{
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'materialSerial': item.materialSerial,
                  'lessonIndex': item.lessonIndex,
                  'segmentIndex': item.segmentIndex
                }),
        _segmentInsertionAdapter = InsertionAdapter(
            database,
            'Segment',
            (Segment item) => <String, Object?>{
                  'segmentKeyId': item.segmentKeyId,
                  'classroomId': item.classroomId,
                  'materialSerial': item.materialSerial,
                  'lessonIndex': item.lessonIndex,
                  'segmentIndex': item.segmentIndex,
                  'sort': item.sort
                }),
        _segmentOverallPrgInsertionAdapter = InsertionAdapter(
            database,
            'SegmentOverallPrg',
            (SegmentOverallPrg item) => <String, Object?>{
                  'segmentKeyId': item.segmentKeyId,
                  'classroomId': item.classroomId,
                  'materialSerial': item.materialSerial,
                  'next': _dateConverter.encode(item.next),
                  'progress': item.progress
                }),
        _crKvDeletionAdapter = DeletionAdapter(
            database,
            'CrKv',
            ['classroomId', 'k'],
            (CrKv item) => <String, Object?>{
                  'classroomId': item.classroomId,
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

  final DeletionAdapter<CrKv> _crKvDeletionAdapter;

  @override
  Future<void> forUpdate() async {
    await _queryAdapter
        .queryNoReturn('SELECT * FROM Lock where id=1 for update');
  }

  @override
  Future<void> hideMaterial(int id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Material set hide=true WHERE Material.id=?1',
        arguments: [id]);
  }

  @override
  Future<int?> intKv(
    int classroomId,
    CrK k,
  ) async {
    return _queryAdapter.query(
        'SELECT CAST(value as INTEGER) FROM CrKv WHERE classroomId=?1 and k=?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, _crKConverter.encode(k)]);
  }

  @override
  Future<String?> stringKv(
    int classroomId,
    CrK k,
  ) async {
    return _queryAdapter.query(
        'SELECT value FROM CrKv WHERE classroomId=?1 and k=?2',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [classroomId, _crKConverter.encode(k)]);
  }

  @override
  Future<void> updateKv(
    int classroomId,
    CrK k,
    String value,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE CrKv SET value=?3 WHERE classroomId=?1 and k=?2',
        arguments: [classroomId, _crKConverter.encode(k), value]);
  }

  @override
  Future<void> deleteSegmentTodayPrgByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM SegmentTodayPrg WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> deleteSegmentTodayReviewPrgByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM SegmentTodayPrg where classroomId=?1 and reviewCreateDate!=0',
        arguments: [classroomId]);
  }

  @override
  Future<void> deleteSegmentTodayLearnPrgByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM SegmentTodayPrg where classroomId=?1 and reviewCreateDate=0',
        arguments: [classroomId]);
  }

  @override
  Future<List<SegmentTodayPrg>> findSegmentTodayPrg(int classroomId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM SegmentTodayPrg WHERE classroomId=?1 order by id asc',
        mapper: (Map<String, Object?> row) => SegmentTodayPrg(
            row['classroomId'] as int,
            row['materialSerial'] as int,
            row['segmentKeyId'] as int,
            row['type'] as int,
            row['sort'] as int,
            row['progress'] as int,
            _dateTimeConverter.decode(row['viewTime'] as int),
            row['reviewCount'] as int,
            _dateConverter.decode(row['reviewCreateDate'] as int),
            (row['finish'] as int) != 0,
            id: row['id'] as int?),
        arguments: [classroomId]);
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
  Future<int?> lessonCount(
    int classroomId,
    int materialSerial,
    int lessonIndex,
  ) async {
    return _queryAdapter.query(
        'SELECT count(Segment.segmentKeyId) FROM Segment AND Segment.classroomId=?1 WHERE Segment.materialSerial=?2 and Segment.lessonIndex=?3',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, materialSerial, lessonIndex]);
  }

  @override
  Future<int?> findReviewedMinCreateDate(
    int classroomId,
    int reviewCount,
    Date now,
  ) async {
    return _queryAdapter.query(
        'SELECT IFNULL(MIN(createDate),-1) FROM SegmentReview WHERE classroomId=?1 AND count=?2 and createDate<=?3 order by createDate',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, reviewCount, _dateConverter.encode(now)]);
  }

  @override
  Future<List<SegmentTodayPrg>> scheduleReview(
    int classroomId,
    int reviewCount,
    Date startDate,
  ) async {
    return _queryAdapter.queryList(
        'SELECT SegmentReview.classroomId,SegmentReview.segmentKeyId,0 type,Segment.sort,0 progress,0 viewTime,SegmentReview.count reviewCount,SegmentReview.createDate reviewCreateDate,0 finish FROM SegmentReview JOIN Segment ON Segment.segmentKeyId=SegmentReview.segmentKeyId WHERE SegmentReview.classroomId=?1 AND SegmentReview.count=?2 AND SegmentReview.createDate=?3 ORDER BY Segment.sort',
        mapper: (Map<String, Object?> row) => SegmentTodayPrg(row['classroomId'] as int, row['materialSerial'] as int, row['segmentKeyId'] as int, row['type'] as int, row['sort'] as int, row['progress'] as int, _dateTimeConverter.decode(row['viewTime'] as int), row['reviewCount'] as int, _dateConverter.decode(row['reviewCreateDate'] as int), (row['finish'] as int) != 0, id: row['id'] as int?),
        arguments: [
          classroomId,
          reviewCount,
          _dateConverter.encode(startDate)
        ]);
  }

  @override
  Future<List<SegmentTodayPrg>> scheduleLearn(
    int classroomId,
    int minProgress,
    Date now,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ( SELECT Segment.classroomId,Segment.materialSerial,SegmentOverallPrg.segmentKeyId,0 type,Segment.sort,SegmentOverallPrg.progress progress,0 viewTime,0 reviewCount,0 reviewCreateDate,0 finish FROM SegmentOverallPrg JOIN Segment ON Segment.segmentKeyId=SegmentOverallPrg.segmentKeyId AND Segment.classroomId=?1 WHERE SegmentOverallPrg.next<=?3 AND SegmentOverallPrg.progress>=?2 ORDER BY SegmentOverallPrg.progress,Segment.sort ) Segment order by Segment.sort',
        mapper: (Map<String, Object?> row) => SegmentTodayPrg(row['classroomId'] as int, row['materialSerial'] as int, row['segmentKeyId'] as int, row['type'] as int, row['sort'] as int, row['progress'] as int, _dateTimeConverter.decode(row['viewTime'] as int), row['reviewCount'] as int, _dateConverter.decode(row['reviewCreateDate'] as int), (row['finish'] as int) != 0, id: row['id'] as int?),
        arguments: [classroomId, minProgress, _dateConverter.encode(now)]);
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
            row['classroomId'] as int,
            row['materialSerial'] as int,
            _dateConverter.decode(row['next'] as int),
            row['progress'] as int),
        arguments: [segmentKeyId]);
  }

  @override
  Future<List<SegmentOverallPrgWithKey>> getAllSegmentOverallPrg(
      int classroomId) async {
    return _queryAdapter.queryList(
        'SELECT SegmentOverallPrg.*,Material.name materialName,Segment.lessonIndex,Segment.segmentIndex FROM Segment JOIN SegmentOverallPrg on SegmentOverallPrg.segmentKeyId=Segment.classroomId JOIN Material ON Material.classroomId=Segment.classroomId AND Material.serial=Segment.materialSerial WHERE Segment.classroomId=?1 ORDER BY Segment.sort asc',
        mapper: (Map<String, Object?> row) => SegmentOverallPrgWithKey(row['segmentKeyId'] as int, row['classroomId'] as int, row['materialSerial'] as int, _dateConverter.decode(row['next'] as int), row['progress'] as int, row['materialName'] as String, row['lessonIndex'] as int, row['segmentIndex'] as int),
        arguments: [classroomId]);
  }

  @override
  Future<List<SegmentReviewWithKey>> getAllSegmentReview(
      int classroomId) async {
    return _queryAdapter.queryList(
        'SELECT SegmentReview.*,Material.name materialName,Segment.lessonIndex,Segment.segmentIndex FROM Segment JOIN SegmentReview on SegmentReview.segmentKeyId=Segment.classroomId JOIN Material ON Material.classroomId=Segment.classroomId AND Material.serial=Segment.materialSerial WHERE Segment.classroomId=?1 ORDER BY SegmentReview.createDate desc,Segment.sort asc',
        mapper: (Map<String, Object?> row) => SegmentReviewWithKey(_dateConverter.decode(row['createDate'] as int), row['segmentKeyId'] as int, row['classroomId'] as int, row['materialSerial'] as int, row['count'] as int, row['materialName'] as String, row['lessonIndex'] as int, row['segmentIndex'] as int),
        arguments: [classroomId]);
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
        'SELECT Segment.segmentKeyId,Segment.classroomId,Segment.materialSerial,Segment.lessonIndex,Segment.segmentIndex,Segment.sort sort,Material.name materialName FROM Segment JOIN Material ON Material.classroomId=Segment.classroomId AND Material.serial=Segment.materialSerial WHERE Segment.segmentKeyId=?1',
        mapper: (Map<String, Object?> row) => SegmentContentInDb(row['segmentKeyId'] as int, row['classroomId'] as int, row['materialSerial'] as int, row['lessonIndex'] as int, row['segmentIndex'] as int, row['sort'] as int, row['materialName'] as String),
        arguments: [segmentKeyId]);
  }

  @override
  Future<int?> getPrevSegmentKeyIdWithOffset(
    int classroomId,
    int segmentKeyId,
    int offset,
  ) async {
    return _queryAdapter.query(
        'SELECT LimitSegment.segmentKeyId FROM (SELECT sort,segmentKeyId  FROM Segment  WHERE classroomId=?1  AND sort<(SELECT Segment.sort FROM Segment WHERE Segment.segmentKeyId=?2)  ORDER BY sort desc  LIMIT ?3) LimitSegment  ORDER BY LimitSegment.sort LIMIT 1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, segmentKeyId, offset]);
  }

  @override
  Future<int?> getNextSegmentKeyIdWithOffset(
    int classroomId,
    int segmentKeyId,
    int offset,
  ) async {
    return _queryAdapter.query(
        'SELECT LimitSegment.segmentKeyId FROM (SELECT sort,segmentKeyId  FROM Segment  WHERE classroomId=?1  AND sort>(SELECT Segment.sort FROM Segment WHERE Segment.segmentKeyId=?2)  ORDER BY sort  LIMIT ?3) LimitSegment  ORDER BY LimitSegment.sort desc LIMIT 1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, segmentKeyId, offset]);
  }

  @override
  Future<List<SegmentKey>> getSegmentKey(
    int classroomId,
    int materialSerial,
  ) async {
    return _queryAdapter.queryList(
        'SELECT SegmentKey.* FROM SegmentKey WHERE SegmentKey.classroomId=?1 and SegmentKey.materialSerial=?2',
        mapper: (Map<String, Object?> row) => SegmentKey(row['classroomId'] as int, row['materialSerial'] as int, row['lessonIndex'] as int, row['segmentIndex'] as int, id: row['id'] as int?),
        arguments: [classroomId, materialSerial]);
  }

  @override
  Future<void> deleteSegmentByMaterialSerial(
    int classroomId,
    int materialSerial,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Segment WHERE Segment.classroomId=?1 and Segment.materialSerial=?2',
        arguments: [classroomId, materialSerial]);
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
  Future<void> deleteSegmentByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Segment WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> deleteSegmentKeyByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM SegmentKey WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> deleteSegmentOverallPrgByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM SegmentOverallPrg WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> deleteSegmentReviewByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM SegmentReview WHERE classroomId=?1',
        arguments: [classroomId]);
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
  Future<void> deleteByClassroomId(int classroomId) async {
    if (database is sqflite.Transaction) {
      await super.deleteByClassroomId(classroomId);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.scheduleDao.deleteByClassroomId(classroomId);
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
  Future<void> hideMaterialAndDeleteSegment(
    int materialId,
    int materialSerial,
  ) async {
    if (database is sqflite.Transaction) {
      await super.hideMaterialAndDeleteSegment(materialId, materialSerial);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.scheduleDao
            .hideMaterialAndDeleteSegment(materialId, materialSerial);
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
  Future<List<SegmentTodayPrg>> forceInitToday(TodayPrgType type) async {
    if (database is sqflite.Transaction) {
      return super.forceInitToday(type);
    } else {
      return (database as sqflite.Database)
          .transaction<List<SegmentTodayPrg>>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        return transactionDatabase.scheduleDao.forceInitToday(type);
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
  Future<void> right(
    SegmentTodayPrg segmentTodayPrg,
    int? progress,
  ) async {
    if (database is sqflite.Transaction) {
      await super.right(segmentTodayPrg, progress);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.scheduleDao.right(segmentTodayPrg, progress);
      });
    }
  }
}

class _$BaseDao extends BaseDao {
  _$BaseDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _lockInsertionAdapter = InsertionAdapter(
            database, 'Lock', (Lock item) => <String, Object?>{'id': item.id});

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Lock> _lockInsertionAdapter;

  @override
  Future<Lock?> getLock() async {
    return _queryAdapter.query('SELECT * FROM Lock limit 1',
        mapper: (Map<String, Object?> row) => Lock(row['id'] as int));
  }

  @override
  Future<void> insertLock(Lock entity) async {
    await _lockInsertionAdapter.insert(entity, OnConflictStrategy.replace);
  }
}

// ignore_for_file: unused_element
final _kConverter = KConverter();
final _crKConverter = CrKConverter();
final _dateTimeConverter = DateTimeConverter();
final _dateConverter = DateConverter();
