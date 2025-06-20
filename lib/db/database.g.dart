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

  BookContentVersionDao? _bookContentVersionDaoInstance;

  BookDao? _bookDaoInstance;

  ChapterContentVersionDao? _chapterContentVersionDaoInstance;

  ChapterDao? _chapterDaoInstance;

  ChapterKeyDao? _chapterKeyDaoInstance;

  ClassroomDao? _classroomDaoInstance;

  CrKvDao? _crKvDaoInstance;

  LockDao? _lockDaoInstance;

  GameUserDao? _gameUserDaoInstance;

  GameDao? _gameDaoInstance;

  GameUserInputDao? _gameUserInputDaoInstance;

  KvDao? _kvDaoInstance;

  DocDao? _docDaoInstance;

  TimeStatsDao? _timeStatsDaoInstance;

  ScheduleDao? _scheduleDaoInstance;

  VerseContentVersionDao? _verseContentVersionDaoInstance;

  VerseDao? _verseDaoInstance;

  VerseKeyDao? _verseKeyDaoInstance;

  VerseOverallPrgDao? _verseOverallPrgDaoInstance;

  StatsDao? _statsDaoInstance;

  VerseReviewDao? _verseReviewDaoInstance;

  VerseStatsDao? _verseStatsDaoInstance;

  VerseTodayPrgDao? _verseTodayPrgDaoInstance;

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
            'CREATE TABLE IF NOT EXISTS `Book` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `classroomId` INTEGER NOT NULL, `name` TEXT NOT NULL, `desc` TEXT NOT NULL, `docId` INTEGER NOT NULL, `url` TEXT NOT NULL, `content` TEXT NOT NULL, `contentVersion` INTEGER NOT NULL, `sort` INTEGER NOT NULL, `hide` INTEGER NOT NULL, `chapterWarning` INTEGER NOT NULL, `verseWarning` INTEGER NOT NULL, `createTime` INTEGER NOT NULL, `updateTime` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `BookContentVersion` (`classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `version` INTEGER NOT NULL, `reason` INTEGER NOT NULL, `content` TEXT NOT NULL, `createTime` INTEGER NOT NULL, PRIMARY KEY (`bookId`, `version`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Chapter` (`chapterKeyId` INTEGER NOT NULL, `classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterIndex` INTEGER NOT NULL, PRIMARY KEY (`chapterKeyId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ChapterContentVersion` (`classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterKeyId` INTEGER NOT NULL, `version` INTEGER NOT NULL, `reason` INTEGER NOT NULL, `content` TEXT NOT NULL, `createTime` INTEGER NOT NULL, PRIMARY KEY (`chapterKeyId`, `version`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ChapterKey` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterIndex` INTEGER NOT NULL, `version` INTEGER NOT NULL, `content` TEXT NOT NULL, `contentVersion` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Kv` (`k` TEXT NOT NULL, `value` TEXT NOT NULL, PRIMARY KEY (`k`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Doc` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `url` TEXT NOT NULL, `path` TEXT NOT NULL, `count` INTEGER NOT NULL, `total` INTEGER NOT NULL, `msg` TEXT NOT NULL, `hash` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Classroom` (`id` INTEGER NOT NULL, `name` TEXT NOT NULL, `sort` INTEGER NOT NULL, `hide` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `CrKv` (`classroomId` INTEGER NOT NULL, `k` TEXT NOT NULL, `value` TEXT NOT NULL, PRIMARY KEY (`classroomId`, `k`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Verse` (`verseKeyId` INTEGER NOT NULL, `classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterKeyId` INTEGER NOT NULL, `chapterIndex` INTEGER NOT NULL, `verseIndex` INTEGER NOT NULL, `sort` INTEGER NOT NULL, PRIMARY KEY (`verseKeyId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `VerseContentVersion` (`classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterKeyId` INTEGER NOT NULL, `verseKeyId` INTEGER NOT NULL, `t` INTEGER NOT NULL, `version` INTEGER NOT NULL, `reason` INTEGER NOT NULL, `content` TEXT NOT NULL, `createTime` INTEGER NOT NULL, PRIMARY KEY (`verseKeyId`, `t`, `version`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `VerseKey` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterKeyId` INTEGER NOT NULL, `chapterIndex` INTEGER NOT NULL, `verseIndex` INTEGER NOT NULL, `version` INTEGER NOT NULL, `k` TEXT NOT NULL, `content` TEXT NOT NULL, `contentVersion` INTEGER NOT NULL, `note` TEXT NOT NULL, `noteVersion` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `VerseOverallPrg` (`verseKeyId` INTEGER NOT NULL, `classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterKeyId` INTEGER NOT NULL, `next` INTEGER NOT NULL, `progress` INTEGER NOT NULL, PRIMARY KEY (`verseKeyId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `VerseReview` (`createDate` INTEGER NOT NULL, `verseKeyId` INTEGER NOT NULL, `classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `count` INTEGER NOT NULL, PRIMARY KEY (`createDate`, `verseKeyId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `VerseTodayPrg` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterKeyId` INTEGER NOT NULL, `verseKeyId` INTEGER NOT NULL, `time` INTEGER NOT NULL, `type` INTEGER NOT NULL, `sort` INTEGER NOT NULL, `progress` INTEGER NOT NULL, `viewTime` INTEGER NOT NULL, `reviewCount` INTEGER NOT NULL, `reviewCreateDate` INTEGER NOT NULL, `finish` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `VerseStats` (`verseKeyId` INTEGER NOT NULL, `type` INTEGER NOT NULL, `createDate` INTEGER NOT NULL, `createTime` INTEGER NOT NULL, `classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, PRIMARY KEY (`verseKeyId`, `type`, `createDate`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `TimeStats` (`classroomId` INTEGER NOT NULL, `createDate` INTEGER NOT NULL, `createTime` INTEGER NOT NULL, `duration` INTEGER NOT NULL, PRIMARY KEY (`classroomId`, `createDate`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Game` (`id` INTEGER NOT NULL, `time` INTEGER NOT NULL, `verseContent` TEXT NOT NULL, `verseKeyId` INTEGER NOT NULL, `classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterIndex` INTEGER NOT NULL, `verseIndex` INTEGER NOT NULL, `finish` INTEGER NOT NULL, `createTime` INTEGER NOT NULL, `createDate` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `GameUser` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL, `password` TEXT NOT NULL, `nonce` TEXT NOT NULL, `createDate` INTEGER NOT NULL, `token` TEXT NOT NULL, `tokenExpiredDate` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `GameUserInput` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `gameId` INTEGER NOT NULL, `gameUserId` INTEGER NOT NULL, `time` INTEGER NOT NULL, `verseKeyId` INTEGER NOT NULL, `classroomId` INTEGER NOT NULL, `bookSerial` INTEGER NOT NULL, `chapterIndex` INTEGER NOT NULL, `verseIndex` INTEGER NOT NULL, `input` TEXT NOT NULL, `output` TEXT NOT NULL, `createTime` INTEGER NOT NULL, `createDate` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Lock` (`id` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Book_classroomId_name` ON `Book` (`classroomId`, `name`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Book_classroomId_sort` ON `Book` (`classroomId`, `sort`)');
        await database.execute(
            'CREATE INDEX `index_Book_classroomId_updateTime` ON `Book` (`classroomId`, `updateTime`)');
        await database.execute(
            'CREATE INDEX `index_Book_sort_id` ON `Book` (`sort`, `id`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_BookContentVersion_classroomId_version` ON `BookContentVersion` (`classroomId`, `version`)');
        await database.execute(
            'CREATE INDEX `index_Chapter_classroomId` ON `Chapter` (`classroomId`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Chapter_bookId_chapterIndex` ON `Chapter` (`bookId`, `chapterIndex`)');
        await database.execute(
            'CREATE INDEX `index_ChapterContentVersion_classroomId` ON `ChapterContentVersion` (`classroomId`)');
        await database.execute(
            'CREATE INDEX `index_ChapterContentVersion_bookId` ON `ChapterContentVersion` (`bookId`)');
        await database.execute(
            'CREATE INDEX `index_ChapterKey_classroomId` ON `ChapterKey` (`classroomId`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_ChapterKey_bookId_chapterIndex_version` ON `ChapterKey` (`bookId`, `chapterIndex`, `version`)');
        await database
            .execute('CREATE UNIQUE INDEX `index_Doc_path` ON `Doc` (`path`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Classroom_name` ON `Classroom` (`name`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Classroom_sort` ON `Classroom` (`sort`)');
        await database.execute(
            'CREATE INDEX `index_Verse_chapterKeyId` ON `Verse` (`chapterKeyId`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Verse_classroomId_sort` ON `Verse` (`classroomId`, `sort`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Verse_bookId_chapterIndex_verseIndex` ON `Verse` (`bookId`, `chapterIndex`, `verseIndex`)');
        await database.execute(
            'CREATE INDEX `index_VerseContentVersion_classroomId` ON `VerseContentVersion` (`classroomId`)');
        await database.execute(
            'CREATE INDEX `index_VerseContentVersion_bookId` ON `VerseContentVersion` (`bookId`)');
        await database.execute(
            'CREATE INDEX `index_VerseContentVersion_chapterKeyId` ON `VerseContentVersion` (`chapterKeyId`)');
        await database.execute(
            'CREATE INDEX `index_VerseKey_classroomId` ON `VerseKey` (`classroomId`)');
        await database.execute(
            'CREATE INDEX `index_VerseKey_chapterKeyId` ON `VerseKey` (`chapterKeyId`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_VerseKey_bookId_chapterIndex_verseIndex_version` ON `VerseKey` (`bookId`, `chapterIndex`, `verseIndex`, `version`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_VerseKey_bookId_k` ON `VerseKey` (`bookId`, `k`)');
        await database.execute(
            'CREATE INDEX `index_VerseOverallPrg_classroomId_next_progress` ON `VerseOverallPrg` (`classroomId`, `next`, `progress`)');
        await database.execute(
            'CREATE INDEX `index_VerseOverallPrg_classroomId` ON `VerseOverallPrg` (`classroomId`)');
        await database.execute(
            'CREATE INDEX `index_VerseOverallPrg_bookId` ON `VerseOverallPrg` (`bookId`)');
        await database.execute(
            'CREATE INDEX `index_VerseReview_bookId` ON `VerseReview` (`bookId`)');
        await database.execute(
            'CREATE INDEX `index_VerseReview_classroomId_createDate` ON `VerseReview` (`classroomId`, `createDate`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_VerseTodayPrg_verseKeyId_type` ON `VerseTodayPrg` (`verseKeyId`, `type`)');
        await database.execute(
            'CREATE INDEX `index_VerseTodayPrg_classroomId_sort` ON `VerseTodayPrg` (`classroomId`, `sort`)');
        await database.execute(
            'CREATE INDEX `index_VerseTodayPrg_bookId` ON `VerseTodayPrg` (`bookId`)');
        await database.execute(
            'CREATE INDEX `index_VerseStats_bookId` ON `VerseStats` (`bookId`)');
        await database.execute(
            'CREATE INDEX `index_VerseStats_classroomId_createDate` ON `VerseStats` (`classroomId`, `createDate`)');
        await database.execute(
            'CREATE INDEX `index_VerseStats_classroomId_createTime` ON `VerseStats` (`classroomId`, `createTime`)');
        await database.execute(
            'CREATE INDEX `index_Game_classroomId` ON `Game` (`classroomId`)');
        await database.execute(
            'CREATE INDEX `index_Game_bookId_chapterIndex_verseIndex` ON `Game` (`bookId`, `chapterIndex`, `verseIndex`)');
        await database.execute(
            'CREATE INDEX `index_Game_verseKeyId` ON `Game` (`verseKeyId`)');
        await database.execute(
            'CREATE INDEX `index_Game_createDate` ON `Game` (`createDate`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_GameUser_name` ON `GameUser` (`name`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_GameUser_token` ON `GameUser` (`token`)');
        await database.execute(
            'CREATE INDEX `index_GameUserInput_classroomId_bookSerial_chapterIndex_verseIndex` ON `GameUserInput` (`classroomId`, `bookSerial`, `chapterIndex`, `verseIndex`)');
        await database.execute(
            'CREATE INDEX `index_GameUserInput_verseKeyId` ON `GameUserInput` (`verseKeyId`)');
        await database.execute(
            'CREATE INDEX `index_GameUserInput_createDate` ON `GameUserInput` (`createDate`)');
        await database.execute(
            'CREATE INDEX `index_GameUserInput_gameId_gameUserId_time` ON `GameUserInput` (`gameId`, `gameUserId`, `time`)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  BookContentVersionDao get bookContentVersionDao {
    return _bookContentVersionDaoInstance ??=
        _$BookContentVersionDao(database, changeListener);
  }

  @override
  BookDao get bookDao {
    return _bookDaoInstance ??= _$BookDao(database, changeListener);
  }

  @override
  ChapterContentVersionDao get chapterContentVersionDao {
    return _chapterContentVersionDaoInstance ??=
        _$ChapterContentVersionDao(database, changeListener);
  }

  @override
  ChapterDao get chapterDao {
    return _chapterDaoInstance ??= _$ChapterDao(database, changeListener);
  }

  @override
  ChapterKeyDao get chapterKeyDao {
    return _chapterKeyDaoInstance ??= _$ChapterKeyDao(database, changeListener);
  }

  @override
  ClassroomDao get classroomDao {
    return _classroomDaoInstance ??= _$ClassroomDao(database, changeListener);
  }

  @override
  CrKvDao get crKvDao {
    return _crKvDaoInstance ??= _$CrKvDao(database, changeListener);
  }

  @override
  LockDao get lockDao {
    return _lockDaoInstance ??= _$LockDao(database, changeListener);
  }

  @override
  GameUserDao get gameUserDao {
    return _gameUserDaoInstance ??= _$GameUserDao(database, changeListener);
  }

  @override
  GameDao get gameDao {
    return _gameDaoInstance ??= _$GameDao(database, changeListener);
  }

  @override
  GameUserInputDao get gameUserInputDao {
    return _gameUserInputDaoInstance ??=
        _$GameUserInputDao(database, changeListener);
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
  TimeStatsDao get timeStatsDao {
    return _timeStatsDaoInstance ??= _$TimeStatsDao(database, changeListener);
  }

  @override
  ScheduleDao get scheduleDao {
    return _scheduleDaoInstance ??= _$ScheduleDao(database, changeListener);
  }

  @override
  VerseContentVersionDao get verseContentVersionDao {
    return _verseContentVersionDaoInstance ??=
        _$VerseContentVersionDao(database, changeListener);
  }

  @override
  VerseDao get verseDao {
    return _verseDaoInstance ??= _$VerseDao(database, changeListener);
  }

  @override
  VerseKeyDao get verseKeyDao {
    return _verseKeyDaoInstance ??= _$VerseKeyDao(database, changeListener);
  }

  @override
  VerseOverallPrgDao get verseOverallPrgDao {
    return _verseOverallPrgDaoInstance ??=
        _$VerseOverallPrgDao(database, changeListener);
  }

  @override
  StatsDao get statsDao {
    return _statsDaoInstance ??= _$StatsDao(database, changeListener);
  }

  @override
  VerseReviewDao get verseReviewDao {
    return _verseReviewDaoInstance ??=
        _$VerseReviewDao(database, changeListener);
  }

  @override
  VerseStatsDao get verseStatsDao {
    return _verseStatsDaoInstance ??= _$VerseStatsDao(database, changeListener);
  }

  @override
  VerseTodayPrgDao get verseTodayPrgDao {
    return _verseTodayPrgDaoInstance ??=
        _$VerseTodayPrgDao(database, changeListener);
  }
}

class _$BookContentVersionDao extends BookContentVersionDao {
  _$BookContentVersionDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _bookContentVersionInsertionAdapter = InsertionAdapter(
            database,
            'BookContentVersion',
            (BookContentVersion item) => <String, Object?>{
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'version': item.version,
                  'reason': _versionReasonConverter.encode(item.reason),
                  'content': item.content,
                  'createTime': _dateTimeConverter.encode(item.createTime)
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<BookContentVersion>
      _bookContentVersionInsertionAdapter;

  @override
  Future<List<BookContentVersion>> list(int bookId) async {
    return _queryAdapter.queryList(
        'SELECT *  FROM BookContentVersion WHERE bookId=?1',
        mapper: (Map<String, Object?> row) => BookContentVersion(
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            version: row['version'] as int,
            reason: _versionReasonConverter.decode(row['reason'] as int),
            content: row['content'] as String,
            createTime: _dateTimeConverter.decode(row['createTime'] as int)),
        arguments: [bookId]);
  }

  @override
  Future<BookContentVersion?> one(
    int bookId,
    int version,
  ) async {
    return _queryAdapter.query(
        'SELECT *  FROM BookContentVersion WHERE bookId=?1  AND version=?2',
        mapper: (Map<String, Object?> row) => BookContentVersion(
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            version: row['version'] as int,
            reason: _versionReasonConverter.decode(row['reason'] as int),
            content: row['content'] as String,
            createTime: _dateTimeConverter.decode(row['createTime'] as int)),
        arguments: [bookId, version]);
  }

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM BookContentVersion WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> insertOrFail(BookContentVersion entity) async {
    await _bookContentVersionInsertionAdapter.insert(
        entity, OnConflictStrategy.fail);
  }

  @override
  Future<void> insertOrIgnore(BookContentVersion entity) async {
    await _bookContentVersionInsertionAdapter.insert(
        entity, OnConflictStrategy.ignore);
  }

  @override
  Future<void> insertsOrIgnore(List<BookContentVersion> entities) async {
    await _bookContentVersionInsertionAdapter.insertList(
        entities, OnConflictStrategy.ignore);
  }
}

class _$BookDao extends BookDao {
  _$BookDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _bookInsertionAdapter = InsertionAdapter(
            database,
            'Book',
            (Book item) => <String, Object?>{
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'name': item.name,
                  'desc': item.desc,
                  'docId': item.docId,
                  'url': item.url,
                  'content': item.content,
                  'contentVersion': item.contentVersion,
                  'sort': item.sort,
                  'hide': item.hide ? 1 : 0,
                  'chapterWarning': item.chapterWarning ? 1 : 0,
                  'verseWarning': item.verseWarning ? 1 : 0,
                  'createTime': item.createTime,
                  'updateTime': item.updateTime
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Book> _bookInsertionAdapter;

  @override
  Future<List<BookShow>> getAllBook(int classroomId) async {
    return _queryAdapter.queryList(
        'SELECT id bookId,classroomId,name,sort,content bookContent,contentVersion bookContentVersion FROM Book where classroomId=?1 and hide=false and docId!=0 ORDER BY sort',
        mapper: (Map<String, Object?> row) => BookShow(bookId: row['bookId'] as int, classroomId: row['classroomId'] as int, name: row['name'] as String, sort: row['sort'] as int, bookContent: row['bookContent'] as String, bookContentVersion: row['bookContentVersion'] as int),
        arguments: [classroomId]);
  }

  @override
  Future<List<Book>> getAll(int classroomId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Book where classroomId=?1 and hide=false ORDER BY sort',
        mapper: (Map<String, Object?> row) => Book(
            id: row['id'] as int?,
            classroomId: row['classroomId'] as int,
            name: row['name'] as String,
            desc: row['desc'] as String,
            docId: row['docId'] as int,
            url: row['url'] as String,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int,
            sort: row['sort'] as int,
            hide: (row['hide'] as int) != 0,
            chapterWarning: (row['chapterWarning'] as int) != 0,
            verseWarning: (row['verseWarning'] as int) != 0,
            createTime: row['createTime'] as int,
            updateTime: row['updateTime'] as int),
        arguments: [classroomId]);
  }

  @override
  Future<bool?> hasWarning(int classroomId) async {
    return _queryAdapter.query(
        'SELECT max(verseWarning) FROM Book where classroomId=?1 and docId!=0 and hide=false',
        mapper: (Map<String, Object?> row) => (row.values.first as int) != 0,
        arguments: [classroomId]);
  }

  @override
  Future<List<Book>> getAllEnableBook(int classroomId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Book where classroomId=?1 and docId!=0 and hide=false ORDER BY sort',
        mapper: (Map<String, Object?> row) => Book(id: row['id'] as int?, classroomId: row['classroomId'] as int, name: row['name'] as String, desc: row['desc'] as String, docId: row['docId'] as int, url: row['url'] as String, content: row['content'] as String, contentVersion: row['contentVersion'] as int, sort: row['sort'] as int, hide: (row['hide'] as int) != 0, chapterWarning: (row['chapterWarning'] as int) != 0, verseWarning: (row['verseWarning'] as int) != 0, createTime: row['createTime'] as int, updateTime: row['updateTime'] as int),
        arguments: [classroomId]);
  }

  @override
  Future<int?> getMaxSort(int classroomId) async {
    return _queryAdapter.query(
        'SELECT ifnull(max(sort),0) FROM Book WHERE classroomId=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId]);
  }

  @override
  Future<int?> existBySort(
    int classroomId,
    int sort,
  ) async {
    return _queryAdapter.query(
        'SELECT ifnull(sort,0) FROM Book WHERE classroomId=?1 and sort=?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, sort]);
  }

  @override
  Future<Book?> getById(int id) async {
    return _queryAdapter.query('SELECT * FROM Book WHERE id=?1',
        mapper: (Map<String, Object?> row) => Book(
            id: row['id'] as int?,
            classroomId: row['classroomId'] as int,
            name: row['name'] as String,
            desc: row['desc'] as String,
            docId: row['docId'] as int,
            url: row['url'] as String,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int,
            sort: row['sort'] as int,
            hide: (row['hide'] as int) != 0,
            chapterWarning: (row['chapterWarning'] as int) != 0,
            verseWarning: (row['verseWarning'] as int) != 0,
            createTime: row['createTime'] as int,
            updateTime: row['updateTime'] as int),
        arguments: [id]);
  }

  @override
  Future<Book?> getBookByName(
    int classroomId,
    String name,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM Book WHERE classroomId=?1 and name=?2',
        mapper: (Map<String, Object?> row) => Book(
            id: row['id'] as int?,
            classroomId: row['classroomId'] as int,
            name: row['name'] as String,
            desc: row['desc'] as String,
            docId: row['docId'] as int,
            url: row['url'] as String,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int,
            sort: row['sort'] as int,
            hide: (row['hide'] as int) != 0,
            chapterWarning: (row['chapterWarning'] as int) != 0,
            verseWarning: (row['verseWarning'] as int) != 0,
            createTime: row['createTime'] as int,
            updateTime: row['updateTime'] as int),
        arguments: [classroomId, name]);
  }

  @override
  Future<void> updateBookContentVersion(
    int id,
    String content,
    int contentVersion,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Book set content=?2,contentVersion=?3 WHERE Book.id=?1',
        arguments: [id, content, contentVersion]);
  }

  @override
  Future<void> updateBook(
    int id,
    int docId,
    String url,
    bool chapterWarning,
    bool verseWarning,
    int updateTime,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Book set docId=?2,url=?3,chapterWarning=?4,verseWarning=?5,updateTime=?6 WHERE Book.id=?1',
        arguments: [
          id,
          docId,
          url,
          chapterWarning ? 1 : 0,
          verseWarning ? 1 : 0,
          updateTime
        ]);
  }

  @override
  Future<void> updateBookWarning(
    int id,
    bool chapterWarning,
    bool verseWarning,
    int updateTime,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Book set chapterWarning=?2,verseWarning=?3,updateTime=?4 WHERE Book.id=?1',
        arguments: [
          id,
          chapterWarning ? 1 : 0,
          verseWarning ? 1 : 0,
          updateTime
        ]);
  }

  @override
  Future<void> updateBookWarningForChapter(
    int id,
    bool chapterWarning,
    int updateTime,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Book set chapterWarning=?2,updateTime=?3 WHERE Book.id=?1',
        arguments: [id, chapterWarning ? 1 : 0, updateTime]);
  }

  @override
  Future<void> updateBookWarningForVerse(
    int id,
    bool verseWarning,
    int updateTime,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Book set verseWarning=?2,updateTime=?3 WHERE Book.id=?1',
        arguments: [id, verseWarning ? 1 : 0, updateTime]);
  }

  @override
  Future<void> hide(int id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Book set hide=true WHERE Book.id=?1',
        arguments: [id]);
  }

  @override
  Future<void> show(int id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Book set hide=false WHERE Book.id=?1',
        arguments: [id]);
  }

  @override
  Future<void> updateDocId(
    int id,
    int docId,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Book set docId=?2 WHERE Book.id=?1',
        arguments: [id, docId]);
  }

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Book WHERE Book.classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> insertBook(Book entity) async {
    await _bookInsertionAdapter.insert(entity, OnConflictStrategy.fail);
  }

  @override
  Future<void> updateBookContent(
    int bookId,
    String content,
  ) async {
    if (database is sqflite.Transaction) {
      await super.updateBookContent(bookId, content);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.bookDao.updateBookContent(bookId, content);
      });
    }
  }

  @override
  Future<Book> add(String name) async {
    if (database is sqflite.Transaction) {
      return super.add(name);
    } else {
      return (database as sqflite.Database)
          .transaction<Book>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.bookDao.add(name);
      });
    }
  }
}

class _$ChapterContentVersionDao extends ChapterContentVersionDao {
  _$ChapterContentVersionDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _chapterContentVersionInsertionAdapter = InsertionAdapter(
            database,
            'ChapterContentVersion',
            (ChapterContentVersion item) => <String, Object?>{
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterKeyId': item.chapterKeyId,
                  'version': item.version,
                  'reason': _versionReasonConverter.encode(item.reason),
                  'content': item.content,
                  'createTime': _dateTimeConverter.encode(item.createTime)
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ChapterContentVersion>
      _chapterContentVersionInsertionAdapter;

  @override
  Future<List<ChapterContentVersion>> list(int chapterKeyId) async {
    return _queryAdapter.queryList(
        'SELECT *  FROM ChapterContentVersion WHERE chapterKeyId=?1',
        mapper: (Map<String, Object?> row) => ChapterContentVersion(
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterKeyId: row['chapterKeyId'] as int,
            version: row['version'] as int,
            reason: _versionReasonConverter.decode(row['reason'] as int),
            content: row['content'] as String,
            createTime: _dateTimeConverter.decode(row['createTime'] as int)),
        arguments: [chapterKeyId]);
  }

  @override
  Future<List<ChapterContentVersion>> currVersionList(int bookId) async {
    return _queryAdapter.queryList(
        'SELECT ChapterContentVersion.*  FROM ChapterKey JOIN ChapterContentVersion ON ChapterContentVersion.chapterKeyId=ChapterKey.id  AND ChapterContentVersion.version=ChapterKey.contentVersion WHERE ChapterContentVersion.bookId=?1',
        mapper: (Map<String, Object?> row) => ChapterContentVersion(classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterKeyId: row['chapterKeyId'] as int, version: row['version'] as int, reason: _versionReasonConverter.decode(row['reason'] as int), content: row['content'] as String, createTime: _dateTimeConverter.decode(row['createTime'] as int)),
        arguments: [bookId]);
  }

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM ChapterContentVersion WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> deleteByChapterKeyId(int chapterKeyId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM ChapterContentVersion WHERE chapterKeyId=?1',
        arguments: [chapterKeyId]);
  }

  @override
  Future<void> insertOrFail(ChapterContentVersion entity) async {
    await _chapterContentVersionInsertionAdapter.insert(
        entity, OnConflictStrategy.fail);
  }

  @override
  Future<void> insertOrIgnore(ChapterContentVersion entity) async {
    await _chapterContentVersionInsertionAdapter.insert(
        entity, OnConflictStrategy.ignore);
  }

  @override
  Future<void> insertsOrIgnore(List<ChapterContentVersion> entities) async {
    await _chapterContentVersionInsertionAdapter.insertList(
        entities, OnConflictStrategy.ignore);
  }
}

class _$ChapterDao extends ChapterDao {
  _$ChapterDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _chapterInsertionAdapter = InsertionAdapter(
            database,
            'Chapter',
            (Chapter item) => <String, Object?>{
                  'chapterKeyId': item.chapterKeyId,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterIndex': item.chapterIndex
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Chapter> _chapterInsertionAdapter;

  @override
  Future<List<Chapter>> find(int bookId) async {
    return _queryAdapter.queryList('SELECT * FROM Chapter WHERE bookId=?1',
        mapper: (Map<String, Object?> row) => Chapter(
            chapterKeyId: row['chapterKeyId'] as int,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterIndex: row['chapterIndex'] as int),
        arguments: [bookId]);
  }

  @override
  Future<Chapter?> one(
    int bookId,
    int chapterIndex,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM Chapter WHERE bookId=?1 and chapterIndex=?2',
        mapper: (Map<String, Object?> row) => Chapter(
            chapterKeyId: row['chapterKeyId'] as int,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterIndex: row['chapterIndex'] as int),
        arguments: [bookId, chapterIndex]);
  }

  @override
  Future<Chapter?> getById(int chapterKeyId) async {
    return _queryAdapter.query('SELECT * FROM Chapter WHERE chapterKeyId=?1',
        mapper: (Map<String, Object?> row) => Chapter(
            chapterKeyId: row['chapterKeyId'] as int,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterIndex: row['chapterIndex'] as int),
        arguments: [chapterKeyId]);
  }

  @override
  Future<int?> count(int bookId) async {
    return _queryAdapter.query('SELECT count(1) FROM Chapter WHERE bookId=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [bookId]);
  }

  @override
  Future<List<Chapter>> findByMinChapterIndex(
    int bookId,
    int minChapterIndex,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Chapter WHERE bookId=?1 AND chapterIndex>=?2',
        mapper: (Map<String, Object?> row) => Chapter(
            chapterKeyId: row['chapterKeyId'] as int,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterIndex: row['chapterIndex'] as int),
        arguments: [bookId, minChapterIndex]);
  }

  @override
  Future<void> deleteByMinChapterIndex(
    int bookId,
    int minChapterIndex,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Chapter WHERE bookId=?1 AND chapterIndex>=?2',
        arguments: [bookId, minChapterIndex]);
  }

  @override
  Future<void> delete(int bookId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Chapter WHERE Chapter.bookId=?1',
        arguments: [bookId]);
  }

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Chapter WHERE Chapter.classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> deleteById(int id) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM ChapterKey WHERE id=?1', arguments: [id]);
  }

  @override
  Future<void> insertOrFail(List<Chapter> entities) async {
    await _chapterInsertionAdapter.insertList(
        entities, OnConflictStrategy.fail);
  }
}

class _$ChapterKeyDao extends ChapterKeyDao {
  _$ChapterKeyDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _chapterKeyInsertionAdapter = InsertionAdapter(
            database,
            'ChapterKey',
            (ChapterKey item) => <String, Object?>{
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterIndex': item.chapterIndex,
                  'version': item.version,
                  'content': item.content,
                  'contentVersion': item.contentVersion
                }),
        _chapterKeyUpdateAdapter = UpdateAdapter(
            database,
            'ChapterKey',
            ['id'],
            (ChapterKey item) => <String, Object?>{
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterIndex': item.chapterIndex,
                  'version': item.version,
                  'content': item.content,
                  'contentVersion': item.contentVersion
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ChapterKey> _chapterKeyInsertionAdapter;

  final UpdateAdapter<ChapterKey> _chapterKeyUpdateAdapter;

  @override
  Future<ChapterKey?> getById(int id) async {
    return _queryAdapter.query(
        'SELECT * FROM ChapterKey WHERE ChapterKey.id=?1',
        mapper: (Map<String, Object?> row) => ChapterKey(
            id: row['id'] as int?,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterIndex: row['chapterIndex'] as int,
            version: row['version'] as int,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int),
        arguments: [id]);
  }

  @override
  Future<int?> getChapterKeyId(
    int bookId,
    int chapterIndex,
    int version,
  ) async {
    return _queryAdapter.query(
        'SELECT id FROM ChapterKey WHERE bookId=?1 and chapterIndex=?2 and version=?3',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [bookId, chapterIndex, version]);
  }

  @override
  Future<int?> getMissingCount(int bookId) async {
    return _queryAdapter.query(
        'SELECT ifnull(sum(Chapter.chapterKeyId is null),0) missingCount FROM ChapterKey JOIN Book ON Book.id=?1 AND Book.docId!=0 LEFT JOIN Chapter ON Chapter.chapterKeyId=ChapterKey.id',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [bookId]);
  }

  @override
  Future<List<ChapterShow>> getAllChapter(int classroomId) async {
    return _queryAdapter.queryList(
        'SELECT ChapterKey.id chapterKeyId,Book.id bookId,Book.name bookName,Book.sort bookSort,ChapterKey.content chapterContent,ChapterKey.contentVersion chapterContentVersion,ChapterKey.chapterIndex,Chapter.chapterKeyId is null missing FROM ChapterKey JOIN Book ON Book.id=ChapterKey.bookId AND Book.docId!=0 LEFT JOIN Chapter ON Chapter.chapterKeyId=ChapterKey.id WHERE ChapterKey.classroomId=?1',
        mapper: (Map<String, Object?> row) => ChapterShow(chapterKeyId: row['chapterKeyId'] as int, bookId: row['bookId'] as int, bookName: row['bookName'] as String, bookSort: row['bookSort'] as int, chapterContent: row['chapterContent'] as String, chapterContentVersion: row['chapterContentVersion'] as int, chapterIndex: row['chapterIndex'] as int, missing: (row['missing'] as int) != 0),
        arguments: [classroomId]);
  }

  @override
  Future<List<ChapterKey>> findByMinChapterIndex(
    int bookId,
    int minChapterIndex,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ChapterKey WHERE bookId=?1 AND chapterIndex>=?2',
        mapper: (Map<String, Object?> row) => ChapterKey(
            id: row['id'] as int?,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterIndex: row['chapterIndex'] as int,
            version: row['version'] as int,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int),
        arguments: [bookId, minChapterIndex]);
  }

  @override
  Future<void> deleteByMinChapterIndex(
    int bookId,
    int minChapterIndex,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM ChapterKey WHERE bookId=?1 AND chapterIndex>=?2',
        arguments: [bookId, minChapterIndex]);
  }

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM ChapterKey WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> updateKeyAndContent(
    int id,
    String content,
    int contentVersion,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE ChapterKey set content=?2,contentVersion=?3 WHERE id=?1',
        arguments: [id, content, contentVersion]);
  }

  @override
  Future<List<ChapterKey>> findByBook(int bookId) async {
    return _queryAdapter.queryList('SELECT * FROM ChapterKey WHERE bookId=?1',
        mapper: (Map<String, Object?> row) => ChapterKey(
            id: row['id'] as int?,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterIndex: row['chapterIndex'] as int,
            version: row['version'] as int,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int),
        arguments: [bookId]);
  }

  @override
  Future<List<ChapterKey>> findByBookAndVersion(
    int bookId,
    int version,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ChapterKey WHERE bookId=?1 and version=?2',
        mapper: (Map<String, Object?> row) => ChapterKey(
            id: row['id'] as int?,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterIndex: row['chapterIndex'] as int,
            version: row['version'] as int,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int),
        arguments: [bookId, version]);
  }

  @override
  Future<void> deleteById(int id) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM ChapterKey WHERE id=?1', arguments: [id]);
  }

  @override
  Future<void> insertOrFail(List<ChapterKey> entities) async {
    await _chapterKeyInsertionAdapter.insertList(
        entities, OnConflictStrategy.fail);
  }

  @override
  Future<void> updateOrFail(List<ChapterKey> entities) async {
    await _chapterKeyUpdateAdapter.updateList(
        entities, OnConflictStrategy.fail);
  }

  @override
  Future<void> updateChapterContent(
    int chapterKeyId,
    String content,
  ) async {
    if (database is sqflite.Transaction) {
      await super.updateChapterContent(chapterKeyId, content);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.chapterKeyDao
            .updateChapterContent(chapterKeyId, content);
      });
    }
  }

  @override
  Future<bool> deleteAbnormalChapter(int chapterKeyId) async {
    if (database is sqflite.Transaction) {
      return super.deleteAbnormalChapter(chapterKeyId);
    } else {
      return (database as sqflite.Database)
          .transaction<bool>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.chapterKeyDao
            .deleteAbnormalChapter(chapterKeyId);
      });
    }
  }

  @override
  Future<bool> deleteNormalChapter(
    int chapterKeyId,
    Map<String, dynamic> out,
  ) async {
    if (database is sqflite.Transaction) {
      return super.deleteNormalChapter(chapterKeyId, out);
    } else {
      return (database as sqflite.Database)
          .transaction<bool>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.chapterKeyDao
            .deleteNormalChapter(chapterKeyId, out);
      });
    }
  }

  @override
  Future<bool> addChapter(
    ChapterShow chapterShow,
    int chapterIndex,
    Map<String, dynamic> out,
  ) async {
    if (database is sqflite.Transaction) {
      return super.addChapter(chapterShow, chapterIndex, out);
    } else {
      return (database as sqflite.Database)
          .transaction<bool>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.chapterKeyDao
            .addChapter(chapterShow, chapterIndex, out);
      });
    }
  }

  @override
  Future<bool> addFirstChapter(int bookId) async {
    if (database is sqflite.Transaction) {
      return super.addFirstChapter(bookId);
    } else {
      return (database as sqflite.Database)
          .transaction<bool>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.chapterKeyDao.addFirstChapter(bookId);
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
  Future<void> deleteById(int id) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM Classroom WHERE id=?1', arguments: [id]);
  }

  @override
  Future<void> insertClassroom(Classroom entity) async {
    await _classroomInsertionAdapter.insert(entity, OnConflictStrategy.fail);
  }

  @override
  Future<void> deleteAll(int classroomId) async {
    if (database is sqflite.Transaction) {
      await super.deleteAll(classroomId);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.classroomDao.deleteAll(classroomId);
      });
    }
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
        prepareDb(transactionDatabase);
        return transactionDatabase.classroomDao.add(name);
      });
    }
  }
}

class _$CrKvDao extends CrKvDao {
  _$CrKvDao(
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
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<CrKv> _crKvInsertionAdapter;

  @override
  Future<List<CrKv>> find(List<CrK> k) async {
    const offset = 1;
    final _sqliteVariablesForK =
        Iterable<String>.generate(k.length, (i) => '?${i + offset}').join(',');
    return _queryAdapter.queryList(
        'SELECT * FROM CrKv where `k` in (' + _sqliteVariablesForK + ')',
        mapper: (Map<String, Object?> row) => CrKv(row['classroomId'] as int,
            _crKConverter.decode(row['k'] as String), row['value'] as String),
        arguments: [...k.map((element) => _crKConverter.encode(element))]);
  }

  @override
  Future<CrKv?> one(
    int classroomId,
    CrK k,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM CrKv where classroomId=?1 and `k`=?2',
        mapper: (Map<String, Object?> row) => CrKv(row['classroomId'] as int,
            _crKConverter.decode(row['k'] as String), row['value'] as String),
        arguments: [classroomId, _crKConverter.encode(k)]);
  }

  @override
  Future<int?> getInt(
    int classroomId,
    CrK k,
  ) async {
    return _queryAdapter.query(
        'SELECT CAST(value as INTEGER) FROM CrKv WHERE classroomId=?1 and k=?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, _crKConverter.encode(k)]);
  }

  @override
  Future<String?> getString(
    int classroomId,
    CrK k,
  ) async {
    return _queryAdapter.query(
        'SELECT value FROM CrKv WHERE classroomId=?1 and k=?2',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [classroomId, _crKConverter.encode(k)]);
  }

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM CrKv WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> insertOrReplace(CrKv kv) async {
    await _crKvInsertionAdapter.insert(kv, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertsOrReplace(List<CrKv> kv) async {
    await _crKvInsertionAdapter.insertList(kv, OnConflictStrategy.replace);
  }
}

class _$LockDao extends LockDao {
  _$LockDao(
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
  Future<void> forUpdate() async {
    await _queryAdapter
        .queryNoReturn('SELECT * FROM Lock where id=1 for update');
  }

  @override
  Future<Lock?> getLock() async {
    return _queryAdapter.query('SELECT * FROM Lock limit 1',
        mapper: (Map<String, Object?> row) => Lock(row['id'] as int));
  }

  @override
  Future<void> insertLock(Lock entity) async {
    await _lockInsertionAdapter.insert(entity, OnConflictStrategy.ignore);
  }
}

class _$GameUserDao extends GameUserDao {
  _$GameUserDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _gameUserInsertionAdapter = InsertionAdapter(
            database,
            'GameUser',
            (GameUser item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'password': item.password,
                  'nonce': item.nonce,
                  'createDate': _dateConverter.encode(item.createDate),
                  'token': item.token,
                  'tokenExpiredDate':
                      _dateConverter.encode(item.tokenExpiredDate)
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<GameUser> _gameUserInsertionAdapter;

  @override
  Future<GameUser?> findUserByName(String name) async {
    return _queryAdapter.query('SELECT * FROM GameUser WHERE name = ?1',
        mapper: (Map<String, Object?> row) => GameUser(
            row['name'] as String,
            row['password'] as String,
            row['nonce'] as String,
            _dateConverter.decode(row['createDate'] as int),
            row['token'] as String,
            _dateConverter.decode(row['tokenExpiredDate'] as int),
            id: row['id'] as int?),
        arguments: [name]);
  }

  @override
  Future<List<GameUser>> getAllUser() async {
    return _queryAdapter.queryList('SELECT * FROM GameUser',
        mapper: (Map<String, Object?> row) => GameUser(
            row['name'] as String,
            row['password'] as String,
            row['nonce'] as String,
            _dateConverter.decode(row['createDate'] as int),
            row['token'] as String,
            _dateConverter.decode(row['tokenExpiredDate'] as int),
            id: row['id'] as int?));
  }

  @override
  Future<int?> intKv(K k) async {
    return _queryAdapter.query(
        'SELECT CAST(value as INTEGER) FROM Kv where `k`=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [_kConverter.encode(k)]);
  }

  @override
  Future<int?> count() async {
    return _queryAdapter.query('SELECT count(id) FROM GameUser',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<void> updateUserToken(
    int id,
    String token,
    Date tokenExpiredDate,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE GameUser SET token=?2,tokenExpiredDate=?3 WHERE id = ?1',
        arguments: [id, token, _dateConverter.encode(tokenExpiredDate)]);
  }

  @override
  Future<GameUser?> findUserByToken(String token) async {
    return _queryAdapter.query('SELECT * FROM GameUser WHERE token = ?1',
        mapper: (Map<String, Object?> row) => GameUser(
            row['name'] as String,
            row['password'] as String,
            row['nonce'] as String,
            _dateConverter.decode(row['createDate'] as int),
            row['token'] as String,
            _dateConverter.decode(row['tokenExpiredDate'] as int),
            id: row['id'] as int?),
        arguments: [token]);
  }

  @override
  Future<int> registerUser(GameUser user) {
    return _gameUserInsertionAdapter.insertAndReturnId(
        user, OnConflictStrategy.abort);
  }

  @override
  Future<String> loginOrRegister(
    String name,
    String password,
  ) async {
    if (database is sqflite.Transaction) {
      return super.loginOrRegister(name, password);
    } else {
      return (database as sqflite.Database)
          .transaction<String>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.gameUserDao.loginOrRegister(name, password);
      });
    }
  }

  @override
  Future<GameUser> loginByToken(String token) async {
    if (database is sqflite.Transaction) {
      return super.loginByToken(token);
    } else {
      return (database as sqflite.Database)
          .transaction<GameUser>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.gameUserDao.loginByToken(token);
      });
    }
  }
}

class _$GameDao extends GameDao {
  _$GameDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _gameInsertionAdapter = InsertionAdapter(
            database,
            'Game',
            (Game item) => <String, Object?>{
                  'id': item.id,
                  'time': item.time,
                  'verseContent': item.verseContent,
                  'verseKeyId': item.verseKeyId,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterIndex': item.chapterIndex,
                  'verseIndex': item.verseIndex,
                  'finish': item.finish ? 1 : 0,
                  'createTime': item.createTime,
                  'createDate': _dateConverter.encode(item.createDate)
                }),
        _gameUserInputInsertionAdapter = InsertionAdapter(
            database,
            'GameUserInput',
            (GameUserInput item) => <String, Object?>{
                  'id': item.id,
                  'gameId': item.gameId,
                  'gameUserId': item.gameUserId,
                  'time': item.time,
                  'verseKeyId': item.verseKeyId,
                  'classroomId': item.classroomId,
                  'bookSerial': item.bookSerial,
                  'chapterIndex': item.chapterIndex,
                  'verseIndex': item.verseIndex,
                  'input': item.input,
                  'output': item.output,
                  'createTime': item.createTime,
                  'createDate': _dateConverter.encode(item.createDate)
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Game> _gameInsertionAdapter;

  final InsertionAdapter<GameUserInput> _gameUserInputInsertionAdapter;

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
  Future<Game?> getOne() async {
    return _queryAdapter.query('SELECT * FROM Game where finish=false',
        mapper: (Map<String, Object?> row) => Game(
            id: row['id'] as int,
            time: row['time'] as int,
            verseContent: row['verseContent'] as String,
            verseKeyId: row['verseKeyId'] as int,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterIndex: row['chapterIndex'] as int,
            verseIndex: row['verseIndex'] as int,
            finish: (row['finish'] as int) != 0,
            createTime: row['createTime'] as int,
            createDate: _dateConverter.decode(row['createDate'] as int)));
  }

  @override
  Future<void> refreshGame(
    int gameId,
    int time,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Game set time=?2,finish=false where id=?1',
        arguments: [gameId, time]);
  }

  @override
  Future<void> refreshGameContent(
    int gameId,
    String verseContent,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Game set verseContent=?2 where id=?1',
        arguments: [gameId, verseContent]);
  }

  @override
  Future<void> refreshVerseTodayPrg(
    int gameId,
    int time,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE VerseTodayPrg set time=?2 where id=?1',
        arguments: [gameId, time]);
  }

  @override
  Future<List<int>> getAllEnableGameIds() async {
    return _queryAdapter.queryList('SELECT id FROM Game where finish=false',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<void> disableGames(List<int> gameIds) async {
    const offset = 1;
    final _sqliteVariablesForGameIds =
        Iterable<String>.generate(gameIds.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'UPDATE Game set finish=true where id in (' +
            _sqliteVariablesForGameIds +
            ')',
        arguments: [...gameIds]);
  }

  @override
  Future<Game?> one(int gameId) async {
    return _queryAdapter.query('SELECT * FROM Game WHERE id=?1',
        mapper: (Map<String, Object?> row) => Game(
            id: row['id'] as int,
            time: row['time'] as int,
            verseContent: row['verseContent'] as String,
            verseKeyId: row['verseKeyId'] as int,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterIndex: row['chapterIndex'] as int,
            verseIndex: row['verseIndex'] as int,
            finish: (row['finish'] as int) != 0,
            createTime: row['createTime'] as int,
            createDate: _dateConverter.decode(row['createDate'] as int)),
        arguments: [gameId]);
  }

  @override
  Future<GameUserInput?> lastUserInput(
    int gameId,
    int gameUserId,
    int time,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM GameUserInput WHERE gameId=?1 and gameUserId=?2 and time=?3 order by id desc limit 1',
        mapper: (Map<String, Object?> row) => GameUserInput(row['gameId'] as int, row['gameUserId'] as int, row['time'] as int, row['verseKeyId'] as int, row['classroomId'] as int, row['bookSerial'] as int, row['chapterIndex'] as int, row['verseIndex'] as int, row['input'] as String, row['output'] as String, row['createTime'] as int, _dateConverter.decode(row['createDate'] as int), id: row['id'] as int?),
        arguments: [gameId, gameUserId, time]);
  }

  @override
  Future<List<GameUserInput>> gameUserInput(
    int gameId,
    int gameUserId,
    int time,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM GameUserInput WHERE gameId=?1 and gameUserId=?2 and time=?3',
        mapper: (Map<String, Object?> row) => GameUserInput(row['gameId'] as int, row['gameUserId'] as int, row['time'] as int, row['verseKeyId'] as int, row['classroomId'] as int, row['bookSerial'] as int, row['chapterIndex'] as int, row['verseIndex'] as int, row['input'] as String, row['output'] as String, row['createTime'] as int, _dateConverter.decode(row['createDate'] as int), id: row['id'] as int?),
        arguments: [gameId, gameUserId, time]);
  }

  @override
  Future<void> clearGameUser(
    int gameId,
    int gameUserId,
    int time,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM GameUserInput WHERE gameId=?1 and gameUserId=?2 and time=?3',
        arguments: [gameId, gameUserId, time]);
  }

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM Game WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> insertGame(Game game) async {
    await _gameInsertionAdapter.insert(game, OnConflictStrategy.fail);
  }

  @override
  Future<void> insertGameUserInput(GameUserInput gameUserInput) async {
    await _gameUserInputInsertionAdapter.insert(
        gameUserInput, OnConflictStrategy.fail);
  }

  @override
  Future<Game> tryInsertGame(Game game) async {
    if (database is sqflite.Transaction) {
      return super.tryInsertGame(game);
    } else {
      return (database as sqflite.Database)
          .transaction<Game>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.gameDao.tryInsertGame(game);
      });
    }
  }

  @override
  Future<void> clearGame(
    int gameId,
    int userId,
    String verseContent,
  ) async {
    if (database is sqflite.Transaction) {
      await super.clearGame(gameId, userId, verseContent);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.gameDao
            .clearGame(gameId, userId, verseContent);
      });
    }
  }

  @override
  Future<List<String>> getTip(
    int gameId,
    int gameUserId,
  ) async {
    if (database is sqflite.Transaction) {
      return super.getTip(gameId, gameUserId);
    } else {
      return (database as sqflite.Database)
          .transaction<List<String>>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.gameDao.getTip(gameId, gameUserId);
      });
    }
  }

  @override
  Future<GameUserInput> submit(
    int gameId,
    int matchTypeInt,
    int preGameUserInputId,
    int gameUserId,
    String userInput,
    List<String> obtainInput,
    List<String> obtainOutput,
  ) async {
    if (database is sqflite.Transaction) {
      return super.submit(gameId, matchTypeInt, preGameUserInputId, gameUserId,
          userInput, obtainInput, obtainOutput);
    } else {
      return (database as sqflite.Database)
          .transaction<GameUserInput>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.gameDao.submit(
            gameId,
            matchTypeInt,
            preGameUserInputId,
            gameUserId,
            userInput,
            obtainInput,
            obtainOutput);
      });
    }
  }
}

class _$GameUserInputDao extends GameUserInputDao {
  _$GameUserInputDao(
    this.database,
    this.changeListener,
  ) : _queryAdapter = QueryAdapter(database);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM GameUserInput WHERE classroomId=?1',
        arguments: [classroomId]);
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
  Future<int?> getIdByPath(String path) async {
    return _queryAdapter.query('SELECT id FROM Doc WHERE path=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [path]);
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
    String url,
    String path,
    String hash,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE OR ABORT Doc SET msg=\'\',count=total,url=?2,path=?3,hash=?4 WHERE id=?1',
        arguments: [id, url, path, hash]);
  }

  @override
  Future<List<Doc>> getAllDoc(String prefixPath) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Doc WHERE path LIKE ?1 || \'%\'',
        mapper: (Map<String, Object?> row) => Doc(
            row['url'] as String, row['path'] as String, row['hash'] as String,
            id: row['id'] as int?,
            msg: row['msg'] as String,
            count: row['count'] as int,
            total: row['total'] as int),
        arguments: [prefixPath]);
  }

  @override
  Future<void> insertDoc(Doc data) async {
    await _docInsertionAdapter.insert(data, OnConflictStrategy.replace);
  }

  @override
  Future<Doc> insertByPath(String path) async {
    if (database is sqflite.Transaction) {
      return super.insertByPath(path);
    } else {
      return (database as sqflite.Database)
          .transaction<Doc>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.docDao.insertByPath(path);
      });
    }
  }
}

class _$TimeStatsDao extends TimeStatsDao {
  _$TimeStatsDao(
    this.database,
    this.changeListener,
  ) : _queryAdapter = QueryAdapter(database);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM TimeStats WHERE classroomId=?1',
        arguments: [classroomId]);
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
        _verseTodayPrgInsertionAdapter = InsertionAdapter(
            database,
            'VerseTodayPrg',
            (VerseTodayPrg item) => <String, Object?>{
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterKeyId': item.chapterKeyId,
                  'verseKeyId': item.verseKeyId,
                  'time': item.time,
                  'type': item.type,
                  'sort': item.sort,
                  'progress': item.progress,
                  'viewTime': _dateTimeConverter.encode(item.viewTime),
                  'reviewCount': item.reviewCount,
                  'reviewCreateDate':
                      _dateConverter.encode(item.reviewCreateDate),
                  'finish': item.finish ? 1 : 0
                }),
        _verseReviewInsertionAdapter = InsertionAdapter(
            database,
            'VerseReview',
            (VerseReview item) => <String, Object?>{
                  'createDate': _dateConverter.encode(item.createDate),
                  'verseKeyId': item.verseKeyId,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'count': item.count
                }),
        _verseKeyInsertionAdapter = InsertionAdapter(
            database,
            'VerseKey',
            (VerseKey item) => <String, Object?>{
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterKeyId': item.chapterKeyId,
                  'chapterIndex': item.chapterIndex,
                  'verseIndex': item.verseIndex,
                  'version': item.version,
                  'k': item.k,
                  'content': item.content,
                  'contentVersion': item.contentVersion,
                  'note': item.note,
                  'noteVersion': item.noteVersion
                }),
        _verseInsertionAdapter = InsertionAdapter(
            database,
            'Verse',
            (Verse item) => <String, Object?>{
                  'verseKeyId': item.verseKeyId,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterKeyId': item.chapterKeyId,
                  'chapterIndex': item.chapterIndex,
                  'verseIndex': item.verseIndex,
                  'sort': item.sort
                }),
        _verseOverallPrgInsertionAdapter = InsertionAdapter(
            database,
            'VerseOverallPrg',
            (VerseOverallPrg item) => <String, Object?>{
                  'verseKeyId': item.verseKeyId,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterKeyId': item.chapterKeyId,
                  'next': _dateConverter.encode(item.next),
                  'progress': item.progress
                }),
        _verseStatsInsertionAdapter = InsertionAdapter(
            database,
            'VerseStats',
            (VerseStats item) => <String, Object?>{
                  'verseKeyId': item.verseKeyId,
                  'type': item.type,
                  'createDate': _dateConverter.encode(item.createDate),
                  'createTime': item.createTime,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId
                }),
        _verseKeyUpdateAdapter = UpdateAdapter(
            database,
            'VerseKey',
            ['id'],
            (VerseKey item) => <String, Object?>{
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterKeyId': item.chapterKeyId,
                  'chapterIndex': item.chapterIndex,
                  'verseIndex': item.verseIndex,
                  'version': item.version,
                  'k': item.k,
                  'content': item.content,
                  'contentVersion': item.contentVersion,
                  'note': item.note,
                  'noteVersion': item.noteVersion
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

  final InsertionAdapter<VerseTodayPrg> _verseTodayPrgInsertionAdapter;

  final InsertionAdapter<VerseReview> _verseReviewInsertionAdapter;

  final InsertionAdapter<VerseKey> _verseKeyInsertionAdapter;

  final InsertionAdapter<Verse> _verseInsertionAdapter;

  final InsertionAdapter<VerseOverallPrg> _verseOverallPrgInsertionAdapter;

  final InsertionAdapter<VerseStats> _verseStatsInsertionAdapter;

  final UpdateAdapter<VerseKey> _verseKeyUpdateAdapter;

  final DeletionAdapter<CrKv> _crKvDeletionAdapter;

  @override
  Future<Doc?> getDocById(int id) async {
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
  Future<void> forUpdate() async {
    await _queryAdapter
        .queryNoReturn('SELECT * FROM Lock where id=1 for update');
  }

  @override
  Future<void> hideBook(int id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Book set hide=true,docId=0 WHERE Book.id=?1',
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
  Future<void> updateVerseNote(
    int id,
    String note,
    int noteVersion,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE VerseKey set note=?2,noteVersion=?3 WHERE id=?1',
        arguments: [id, note, noteVersion]);
  }

  @override
  Future<void> updateVerseKeyAndContent(
    int id,
    String key,
    String content,
    int contentVersion,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE VerseKey set k=?2,content=?3,contentVersion=?4 WHERE id=?1',
        arguments: [id, key, content, contentVersion]);
  }

  @override
  Future<String?> getVerseNote(int id) async {
    return _queryAdapter.query('SELECT note FROM VerseKey WHERE id=?1',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [id]);
  }

  @override
  Future<void> deleteVerseTodayReviewPrgByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseTodayPrg where classroomId=?1 and reviewCreateDate>100',
        arguments: [classroomId]);
  }

  @override
  Future<void> deleteVerseTodayLearnPrgByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseTodayPrg where classroomId=?1 and reviewCreateDate=0',
        arguments: [classroomId]);
  }

  @override
  Future<void> deleteVerseTodayFullCustomPrgByClassroomId(
      int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseTodayPrg where classroomId=?1 and reviewCreateDate=1',
        arguments: [classroomId]);
  }

  @override
  Future<List<VerseTodayPrg>> findVerseTodayPrg(int classroomId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM VerseTodayPrg WHERE classroomId=?1 order by id asc',
        mapper: (Map<String, Object?> row) => VerseTodayPrg(
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterKeyId: row['chapterKeyId'] as int,
            verseKeyId: row['verseKeyId'] as int,
            time: row['time'] as int,
            type: row['type'] as int,
            sort: row['sort'] as int,
            progress: row['progress'] as int,
            viewTime: _dateTimeConverter.decode(row['viewTime'] as int),
            reviewCount: row['reviewCount'] as int,
            reviewCreateDate:
                _dateConverter.decode(row['reviewCreateDate'] as int),
            finish: (row['finish'] as int) != 0,
            id: row['id'] as int?),
        arguments: [classroomId]);
  }

  @override
  Future<void> setVerseTodayPrg(
    int verseKeyId,
    int type,
    int progress,
    DateTime viewTime,
    bool finish,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE VerseTodayPrg SET progress=?3,viewTime=?4,finish=?5 WHERE verseKeyId=?1 and type=?2',
        arguments: [
          verseKeyId,
          type,
          progress,
          _dateTimeConverter.encode(viewTime),
          finish ? 1 : 0
        ]);
  }

  @override
  Future<int?> findReviewedMinCreateDate(
    int classroomId,
    int reviewCount,
    Date now,
  ) async {
    return _queryAdapter.query(
        'SELECT IFNULL(MIN(VerseReview.createDate),-1) FROM VerseReview JOIN Verse ON Verse.verseKeyId=VerseReview.verseKeyId WHERE VerseReview.classroomId=?1 AND VerseReview.count=?2 and VerseReview.createDate<=?3 order by VerseReview.createDate',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, reviewCount, _dateConverter.encode(now)]);
  }

  @override
  Future<List<VerseTodayPrg>> scheduleReview(
    int classroomId,
    int reviewCount,
    Date startDate,
  ) async {
    return _queryAdapter.queryList(
        'SELECT VerseReview.classroomId,Verse.bookId,Chapter.chapterKeyId,VerseReview.verseKeyId,0 time,0 type,Verse.sort,0 progress,0 viewTime,VerseReview.count reviewCount,VerseReview.createDate reviewCreateDate,0 finish FROM VerseReview JOIN Verse ON Verse.verseKeyId=VerseReview.verseKeyId JOIN Chapter ON Chapter.bookId=Verse.bookId  AND Chapter.chapterIndex=Verse.chapterIndex WHERE VerseReview.classroomId=?1 AND VerseReview.count=?2 AND VerseReview.createDate=?3 ORDER BY Verse.sort',
        mapper: (Map<String, Object?> row) => VerseTodayPrg(classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterKeyId: row['chapterKeyId'] as int, verseKeyId: row['verseKeyId'] as int, time: row['time'] as int, type: row['type'] as int, sort: row['sort'] as int, progress: row['progress'] as int, viewTime: _dateTimeConverter.decode(row['viewTime'] as int), reviewCount: row['reviewCount'] as int, reviewCreateDate: _dateConverter.decode(row['reviewCreateDate'] as int), finish: (row['finish'] as int) != 0, id: row['id'] as int?),
        arguments: [
          classroomId,
          reviewCount,
          _dateConverter.encode(startDate)
        ]);
  }

  @override
  Future<List<VerseTodayPrg>> scheduleLearn(
    int classroomId,
    int minProgress,
    Date now,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ( SELECT Verse.classroomId,Verse.bookId,Chapter.chapterKeyId,VerseOverallPrg.verseKeyId,0 time,0 type,Verse.sort,VerseOverallPrg.progress progress,0 viewTime,0 reviewCount,0 reviewCreateDate,0 finish FROM VerseOverallPrg JOIN Verse ON Verse.verseKeyId=VerseOverallPrg.verseKeyId  AND Verse.classroomId=?1 JOIN Chapter ON Chapter.bookId=Verse.bookId  AND Chapter.chapterIndex=Verse.chapterIndex WHERE VerseOverallPrg.next<=?3  AND VerseOverallPrg.progress>=?2 ORDER BY VerseOverallPrg.progress,Verse.sort ) Verse order by Verse.sort',
        mapper: (Map<String, Object?> row) => VerseTodayPrg(classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterKeyId: row['chapterKeyId'] as int, verseKeyId: row['verseKeyId'] as int, time: row['time'] as int, type: row['type'] as int, sort: row['sort'] as int, progress: row['progress'] as int, viewTime: _dateTimeConverter.decode(row['viewTime'] as int), reviewCount: row['reviewCount'] as int, reviewCreateDate: _dateConverter.decode(row['reviewCreateDate'] as int), finish: (row['finish'] as int) != 0, id: row['id'] as int?),
        arguments: [classroomId, minProgress, _dateConverter.encode(now)]);
  }

  @override
  Future<List<VerseTodayPrg>> scheduleFullCustom(
    int classroomId,
    int bookId,
    int chapterIndex,
    int verseIndex,
    int limit,
  ) async {
    return _queryAdapter.queryList(
        'SELECT Verse.classroomId,Verse.bookId,Chapter.chapterKeyId,Verse.verseKeyId,0 time,0 type,Verse.sort,0 progress,0 viewTime,0 reviewCount,1 reviewCreateDate,0 finish FROM Verse JOIN Chapter ON Chapter.bookId=Verse.bookId  AND Chapter.chapterIndex=Verse.chapterIndex WHERE Verse.classroomId=?1 AND Verse.sort>=(  SELECT Verse.sort FROM Verse  WHERE Verse.bookId=?2  AND Verse.chapterIndex=?3  AND Verse.verseIndex=?4) ORDER BY Verse.sort limit ?5',
        mapper: (Map<String, Object?> row) => VerseTodayPrg(classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterKeyId: row['chapterKeyId'] as int, verseKeyId: row['verseKeyId'] as int, time: row['time'] as int, type: row['type'] as int, sort: row['sort'] as int, progress: row['progress'] as int, viewTime: _dateTimeConverter.decode(row['viewTime'] as int), reviewCount: row['reviewCount'] as int, reviewCreateDate: _dateConverter.decode(row['reviewCreateDate'] as int), finish: (row['finish'] as int) != 0, id: row['id'] as int?),
        arguments: [classroomId, bookId, chapterIndex, verseIndex, limit]);
  }

  @override
  Future<void> setPrgAndNext4Sop(
    int verseKeyId,
    int progress,
    Date next,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE VerseOverallPrg SET progress=?2,next=?3 WHERE verseKeyId=?1',
        arguments: [verseKeyId, progress, _dateConverter.encode(next)]);
  }

  @override
  Future<void> setPrg4Sop(
    int verseKeyId,
    int progress,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE VerseOverallPrg SET progress=?2 WHERE verseKeyId=?1',
        arguments: [verseKeyId, progress]);
  }

  @override
  Future<int?> getVerseProgress(int verseKeyId) async {
    return _queryAdapter.query(
        'SELECT progress FROM VerseOverallPrg WHERE verseKeyId=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [verseKeyId]);
  }

  @override
  Future<List<VerseOverallPrgWithKey>> getAllVerseOverallPrg(
      int classroomId) async {
    return _queryAdapter.queryList(
        'SELECT VerseOverallPrg.*,Book.name contentName,Verse.chapterIndex,Verse.verseIndex FROM Verse JOIN VerseOverallPrg on VerseOverallPrg.verseKeyId=Verse.verseKeyId JOIN Book ON Book.id=Verse.bookId WHERE Verse.classroomId=?1 ORDER BY Verse.sort asc',
        mapper: (Map<String, Object?> row) => VerseOverallPrgWithKey(verseKeyId: row['verseKeyId'] as int, classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterKeyId: row['chapterKeyId'] as int, next: _dateConverter.decode(row['next'] as int), progress: row['progress'] as int, contentName: row['contentName'] as String, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int),
        arguments: [classroomId]);
  }

  @override
  Future<String?> getBookNameById(int bookId) async {
    return _queryAdapter.query('SELECT Book.name FROM Book WHERE Book.id=?1',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [bookId]);
  }

  @override
  Future<List<VerseReviewWithKey>> getAllVerseReview(
    int classroomId,
    Date start,
    Date end,
  ) async {
    return _queryAdapter.queryList(
        'SELECT VerseReview.*,Book.name contentName,Verse.chapterIndex,Verse.verseIndex FROM VerseReview JOIN Verse ON Verse.verseKeyId=VerseReview.verseKeyId JOIN Book ON Book.id=VerseReview.bookId WHERE VerseReview.classroomId=?1 AND VerseReview.createDate>=?2 AND VerseReview.createDate<=?3 ORDER BY VerseReview.createDate desc,Verse.sort asc',
        mapper: (Map<String, Object?> row) => VerseReviewWithKey(createDate: _dateConverter.decode(row['createDate'] as int), verseKeyId: row['verseKeyId'] as int, classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, count: row['count'] as int, contentName: row['contentName'] as String, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int),
        arguments: [
          classroomId,
          _dateConverter.encode(start),
          _dateConverter.encode(end)
        ]);
  }

  @override
  Future<void> setVerseReviewCount(
    Date createDate,
    int verseKeyId,
    int count,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE VerseReview SET count=?3 WHERE createDate=?1 and `verseKeyId`=?2',
        arguments: [_dateConverter.encode(createDate), verseKeyId, count]);
  }

  @override
  Future<String?> getBookName(int verseKeyId) async {
    return _queryAdapter.query(
        'SELECT Book.name contentName FROM VerseKey JOIN Book ON Book.id=VerseKey.bookId WHERE VerseKey.id=?1',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [verseKeyId]);
  }

  @override
  Future<int?> getPrevVerseKeyIdWithOffset(
    int classroomId,
    int verseKeyId,
    int offset,
  ) async {
    return _queryAdapter.query(
        'SELECT LimitVerse.verseKeyId FROM (SELECT sort,verseKeyId  FROM Verse  WHERE classroomId=?1  AND sort<(SELECT Verse.sort FROM Verse WHERE Verse.verseKeyId=?2)  ORDER BY sort desc  LIMIT ?3) LimitVerse  ORDER BY LimitVerse.sort LIMIT 1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, verseKeyId, offset]);
  }

  @override
  Future<int?> getNextVerseKeyIdWithOffset(
    int classroomId,
    int verseKeyId,
    int offset,
  ) async {
    return _queryAdapter.query(
        'SELECT LimitVerse.verseKeyId FROM (SELECT sort,verseKeyId  FROM Verse  WHERE classroomId=?1  AND sort>(SELECT Verse.sort FROM Verse WHERE Verse.verseKeyId=?2)  ORDER BY sort  LIMIT ?3) LimitVerse  ORDER BY LimitVerse.sort desc LIMIT 1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, verseKeyId, offset]);
  }

  @override
  Future<List<KeyId>> getVerseKeyId(int bookId) async {
    return _queryAdapter.queryList(
        'SELECT VerseKey.id,VerseKey.k FROM VerseKey WHERE VerseKey.bookId=?1',
        mapper: (Map<String, Object?> row) =>
            KeyId(row['id'] as int, row['k'] as String),
        arguments: [bookId]);
  }

  @override
  Future<List<VerseKey>> getVerseKey(int bookId) async {
    return _queryAdapter.queryList(
        'SELECT VerseKey.* FROM VerseKey WHERE VerseKey.bookId=?1',
        mapper: (Map<String, Object?> row) => VerseKey(
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterKeyId: row['chapterKeyId'] as int,
            chapterIndex: row['chapterIndex'] as int,
            verseIndex: row['verseIndex'] as int,
            version: row['version'] as int,
            k: row['k'] as String,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int,
            note: row['note'] as String,
            noteVersion: row['noteVersion'] as int,
            id: row['id'] as int?),
        arguments: [bookId]);
  }

  @override
  Future<VerseKey?> getVerseKeyById(int id) async {
    return _queryAdapter.query(
        'SELECT VerseKey.* FROM VerseKey WHERE VerseKey.id=?1',
        mapper: (Map<String, Object?> row) => VerseKey(
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterKeyId: row['chapterKeyId'] as int,
            chapterIndex: row['chapterIndex'] as int,
            verseIndex: row['verseIndex'] as int,
            version: row['version'] as int,
            k: row['k'] as String,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int,
            note: row['note'] as String,
            noteVersion: row['noteVersion'] as int,
            id: row['id'] as int?),
        arguments: [id]);
  }

  @override
  Future<VerseKey?> getVerseKeyByKey(
    int bookId,
    String key,
  ) async {
    return _queryAdapter.query(
        'SELECT VerseKey.* FROM VerseKey WHERE VerseKey.bookId=?1 AND VerseKey.k=?2',
        mapper: (Map<String, Object?> row) => VerseKey(classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterKeyId: row['chapterKeyId'] as int, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int, version: row['version'] as int, k: row['k'] as String, content: row['content'] as String, contentVersion: row['contentVersion'] as int, note: row['note'] as String, noteVersion: row['noteVersion'] as int, id: row['id'] as int?),
        arguments: [bookId, key]);
  }

  @override
  Future<List<VerseShow>> getAllVerse(int classroomId) async {
    return _queryAdapter.queryList(
        'SELECT VerseKey.id verseKeyId,VerseKey.k,Book.id bookId,Book.name bookName,Book.sort bookSort,VerseKey.content verseContent,VerseKey.contentVersion verseContentVersion,VerseKey.note verseNote,VerseKey.noteVersion verseNoteVersion,VerseKey.chapterKeyId,VerseKey.chapterIndex,VerseKey.verseIndex,VerseOverallPrg.next,VerseOverallPrg.progress,Verse.verseKeyId is null missing FROM VerseKey JOIN Book ON Book.id=VerseKey.bookId AND Book.docId!=0 LEFT JOIN Verse ON Verse.verseKeyId=VerseKey.id LEFT JOIN VerseOverallPrg ON VerseOverallPrg.verseKeyId=VerseKey.id WHERE VerseKey.classroomId=?1',
        mapper: (Map<String, Object?> row) => VerseShow(verseKeyId: row['verseKeyId'] as int, k: row['k'] as String, bookId: row['bookId'] as int, bookName: row['bookName'] as String, bookSort: row['bookSort'] as int, verseContent: row['verseContent'] as String, verseContentVersion: row['verseContentVersion'] as int, verseNote: row['verseNote'] as String, verseNoteVersion: row['verseNoteVersion'] as int, chapterKeyId: row['chapterKeyId'] as int, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int, next: _dateConverter.decode(row['next'] as int), progress: row['progress'] as int, missing: (row['missing'] as int) != 0),
        arguments: [classroomId]);
  }

  @override
  Future<List<VerseShow>> getVerseByChapterIndex(
    int bookId,
    int chapterIndex,
  ) async {
    return _queryAdapter.queryList(
        'SELECT VerseKey.id verseKeyId,VerseKey.k,Book.id bookId,Book.name bookName,Book.sort bookSort,VerseKey.content verseContent,VerseKey.contentVersion verseContentVersion,VerseKey.note verseNote,VerseKey.noteVersion verseNoteVersion,VerseKey.chapterKeyId,VerseKey.chapterIndex,VerseKey.verseIndex,VerseOverallPrg.next,VerseOverallPrg.progress,Verse.verseKeyId is null missing FROM VerseKey JOIN Book ON Book.id=?1 AND Book.docId!=0 LEFT JOIN Verse ON Verse.verseKeyId=VerseKey.id LEFT JOIN VerseOverallPrg ON VerseOverallPrg.verseKeyId=VerseKey.id WHERE VerseKey.bookId=?1  AND VerseKey.chapterIndex=?2',
        mapper: (Map<String, Object?> row) => VerseShow(verseKeyId: row['verseKeyId'] as int, k: row['k'] as String, bookId: row['bookId'] as int, bookName: row['bookName'] as String, bookSort: row['bookSort'] as int, verseContent: row['verseContent'] as String, verseContentVersion: row['verseContentVersion'] as int, verseNote: row['verseNote'] as String, verseNoteVersion: row['verseNoteVersion'] as int, chapterKeyId: row['chapterKeyId'] as int, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int, next: _dateConverter.decode(row['next'] as int), progress: row['progress'] as int, missing: (row['missing'] as int) != 0),
        arguments: [bookId, chapterIndex]);
  }

  @override
  Future<List<VerseShow>> getVerseByMinChapterIndex(
    int bookId,
    int minChapterIndex,
  ) async {
    return _queryAdapter.queryList(
        'SELECT VerseKey.id verseKeyId,VerseKey.k,Book.id bookId,Book.name bookName,Book.sort bookSort,VerseKey.content verseContent,VerseKey.contentVersion verseContentVersion,VerseKey.note verseNote,VerseKey.noteVersion verseNoteVersion,VerseKey.chapterKeyId,VerseKey.chapterIndex,VerseKey.verseIndex,VerseOverallPrg.next,VerseOverallPrg.progress,Verse.verseKeyId is null missing FROM VerseKey JOIN Book ON Book.id=VerseKey.bookId AND Book.docId!=0 LEFT JOIN Verse ON Verse.verseKeyId=VerseKey.id LEFT JOIN VerseOverallPrg ON VerseOverallPrg.verseKeyId=VerseKey.id WHERE VerseKey.bookId=?1  AND VerseKey.chapterIndex>=?2',
        mapper: (Map<String, Object?> row) => VerseShow(verseKeyId: row['verseKeyId'] as int, k: row['k'] as String, bookId: row['bookId'] as int, bookName: row['bookName'] as String, bookSort: row['bookSort'] as int, verseContent: row['verseContent'] as String, verseContentVersion: row['verseContentVersion'] as int, verseNote: row['verseNote'] as String, verseNoteVersion: row['verseNoteVersion'] as int, chapterKeyId: row['chapterKeyId'] as int, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int, next: _dateConverter.decode(row['next'] as int), progress: row['progress'] as int, missing: (row['missing'] as int) != 0),
        arguments: [bookId, minChapterIndex]);
  }

  @override
  Future<void> deleteVerse(int verseKeyId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM Verse WHERE verseKeyId=?1',
        arguments: [verseKeyId]);
  }

  @override
  Future<void> deleteVerseKey(int verseKeyId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM VerseKey WHERE id=?1',
        arguments: [verseKeyId]);
  }

  @override
  Future<void> deleteVerseOverallPrg(int verseKeyId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseOverallPrg WHERE verseKeyId=?1',
        arguments: [verseKeyId]);
  }

  @override
  Future<void> deleteVerseReview(int verseKeyId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseReview WHERE verseKeyId=?1',
        arguments: [verseKeyId]);
  }

  @override
  Future<void> deleteVerseTodayPrg(int verseKeyId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseTodayPrg WHERE verseKeyId=?1',
        arguments: [verseKeyId]);
  }

  @override
  Future<int?> getMaxChapterIndex(int bookId) async {
    return _queryAdapter.query(
        'SELECT ifnull(max(Verse.chapterIndex),0) FROM Verse WHERE Verse.bookId=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [bookId]);
  }

  @override
  Future<int?> getMaxVerseIndex(
    int bookId,
    int chapterIndex,
  ) async {
    return _queryAdapter.query(
        'SELECT ifnull(max(Verse.verseIndex),0) FROM Verse WHERE Verse.bookId=?1 AND Verse.chapterIndex=?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [bookId, chapterIndex]);
  }

  @override
  Future<int?> getMaxVerseStatsId(int classroomId) async {
    return _queryAdapter.query(
        'SELECT ifnull(max(VerseStats.id),0) FROM VerseStats WHERE VerseStats.classroomId=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId]);
  }

  @override
  Future<int?> getMaxBookUpdateTime(int classroomId) async {
    return _queryAdapter.query(
        'SELECT ifnull(max(Book.updateTime),0) FROM Book WHERE Book.classroomId=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId]);
  }

  @override
  Future<void> insertKv(CrKv kv) async {
    await _crKvInsertionAdapter.insert(kv, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertVerseTodayPrg(List<VerseTodayPrg> entities) async {
    await _verseTodayPrgInsertionAdapter.insertList(
        entities, OnConflictStrategy.fail);
  }

  @override
  Future<void> insertVerseReview(List<VerseReview> review) async {
    await _verseReviewInsertionAdapter.insertList(
        review, OnConflictStrategy.fail);
  }

  @override
  Future<void> insertVerseKeys(List<VerseKey> entities) async {
    await _verseKeyInsertionAdapter.insertList(
        entities, OnConflictStrategy.ignore);
  }

  @override
  Future<void> insertVerses(List<Verse> entities) async {
    await _verseInsertionAdapter.insertList(
        entities, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertVerseOverallPrgs(List<VerseOverallPrg> entities) async {
    await _verseOverallPrgInsertionAdapter.insertList(
        entities, OnConflictStrategy.ignore);
  }

  @override
  Future<void> insertVerseStats(VerseStats stats) async {
    await _verseStatsInsertionAdapter.insert(stats, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateVerseKeys(List<VerseKey> entities) async {
    await _verseKeyUpdateAdapter.updateList(entities, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteKv(CrKv kv) async {
    await _crKvDeletionAdapter.delete(kv);
  }

  @override
  Future<void> deleteAbnormalVerse(int verseKeyId) async {
    if (database is sqflite.Transaction) {
      await super.deleteAbnormalVerse(verseKeyId);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.scheduleDao.deleteAbnormalVerse(verseKeyId);
      });
    }
  }

  @override
  Future<int> importVerse(
    int bookId,
    int? indexJsonDocId,
    String? url,
  ) async {
    if (database is sqflite.Transaction) {
      return super.importVerse(bookId, indexJsonDocId, url);
    } else {
      return (database as sqflite.Database)
          .transaction<int>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.scheduleDao
            .importVerse(bookId, indexJsonDocId, url);
      });
    }
  }

  @override
  Future<bool> deleteNormalVerse(int verseKeyId) async {
    if (database is sqflite.Transaction) {
      return super.deleteNormalVerse(verseKeyId);
    } else {
      return (database as sqflite.Database)
          .transaction<bool>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.scheduleDao.deleteNormalVerse(verseKeyId);
      });
    }
  }

  @override
  Future<int> addVerse(
    VerseShow raw,
    int verseIndex,
  ) async {
    if (database is sqflite.Transaction) {
      return super.addVerse(raw, verseIndex);
    } else {
      return (database as sqflite.Database)
          .transaction<int>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.scheduleDao.addVerse(raw, verseIndex);
      });
    }
  }

  @override
  Future<int> addFirstVerse(
    int bookId,
    int chapterKeyId,
    int chapterIndex,
  ) async {
    if (database is sqflite.Transaction) {
      return super.addFirstVerse(bookId, chapterKeyId, chapterIndex);
    } else {
      return (database as sqflite.Database)
          .transaction<int>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.scheduleDao
            .addFirstVerse(bookId, chapterKeyId, chapterIndex);
      });
    }
  }

  @override
  Future<void> hideContentAndDeleteVerse(int bookId) async {
    if (database is sqflite.Transaction) {
      await super.hideContentAndDeleteVerse(bookId);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.scheduleDao.hideContentAndDeleteVerse(bookId);
      });
    }
  }

  @override
  Future<List<VerseTodayPrg>> initToday() async {
    if (database is sqflite.Transaction) {
      return super.initToday();
    } else {
      return (database as sqflite.Database)
          .transaction<List<VerseTodayPrg>>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.scheduleDao.initToday();
      });
    }
  }

  @override
  Future<List<VerseTodayPrg>> forceInitToday(TodayPrgType type) async {
    if (database is sqflite.Transaction) {
      return super.forceInitToday(type);
    } else {
      return (database as sqflite.Database)
          .transaction<List<VerseTodayPrg>>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.scheduleDao.forceInitToday(type);
      });
    }
  }

  @override
  Future<void> addFullCustom(
    int bookId,
    int chapterIndex,
    int verseIndex,
    int limit,
  ) async {
    if (database is sqflite.Transaction) {
      await super.addFullCustom(bookId, chapterIndex, verseIndex, limit);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.scheduleDao
            .addFullCustom(bookId, chapterIndex, verseIndex, limit);
      });
    }
  }

  @override
  Future<bool> tUpdateVerseContent(
    int verseKeyId,
    String content,
  ) async {
    if (database is sqflite.Transaction) {
      return super.tUpdateVerseContent(verseKeyId, content);
    } else {
      return (database as sqflite.Database)
          .transaction<bool>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.scheduleDao
            .tUpdateVerseContent(verseKeyId, content);
      });
    }
  }

  @override
  Future<void> tUpdateVerseNote(
    int verseKeyId,
    String note,
  ) async {
    if (database is sqflite.Transaction) {
      await super.tUpdateVerseNote(verseKeyId, note);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.scheduleDao
            .tUpdateVerseNote(verseKeyId, note);
      });
    }
  }

  @override
  Future<void> error(VerseTodayPrg stp) async {
    if (database is sqflite.Transaction) {
      await super.error(stp);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.scheduleDao.error(stp);
      });
    }
  }

  @override
  Future<void> jumpDirectly(
    int verseKeyId,
    int progress,
    int nextDayValue,
  ) async {
    if (database is sqflite.Transaction) {
      await super.jumpDirectly(verseKeyId, progress, nextDayValue);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.scheduleDao
            .jumpDirectly(verseKeyId, progress, nextDayValue);
      });
    }
  }

  @override
  Future<void> jump(
    VerseTodayPrg stp,
    int progress,
    int nextDayValue,
  ) async {
    if (database is sqflite.Transaction) {
      await super.jump(stp, progress, nextDayValue);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.scheduleDao.jump(stp, progress, nextDayValue);
      });
    }
  }

  @override
  Future<void> right(VerseTodayPrg stp) async {
    if (database is sqflite.Transaction) {
      await super.right(stp);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.scheduleDao.right(stp);
      });
    }
  }
}

class _$VerseContentVersionDao extends VerseContentVersionDao {
  _$VerseContentVersionDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _verseContentVersionInsertionAdapter = InsertionAdapter(
            database,
            'VerseContentVersion',
            (VerseContentVersion item) => <String, Object?>{
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterKeyId': item.chapterKeyId,
                  'verseKeyId': item.verseKeyId,
                  't': _verseVersionTypeConverter.encode(item.t),
                  'version': item.version,
                  'reason': _versionReasonConverter.encode(item.reason),
                  'content': item.content,
                  'createTime': _dateTimeConverter.encode(item.createTime)
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<VerseContentVersion>
      _verseContentVersionInsertionAdapter;

  @override
  Future<List<VerseContentVersion>> list(
    int verseKeyId,
    VerseVersionType verseVersionType,
  ) async {
    return _queryAdapter.queryList(
        'SELECT *  FROM VerseContentVersion WHERE verseKeyId=?1 AND t=?2',
        mapper: (Map<String, Object?> row) => VerseContentVersion(
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterKeyId: row['chapterKeyId'] as int,
            verseKeyId: row['verseKeyId'] as int,
            t: _verseVersionTypeConverter.decode(row['t'] as int),
            version: row['version'] as int,
            reason: _versionReasonConverter.decode(row['reason'] as int),
            content: row['content'] as String,
            createTime: _dateTimeConverter.decode(row['createTime'] as int)),
        arguments: [
          verseKeyId,
          _verseVersionTypeConverter.encode(verseVersionType)
        ]);
  }

  @override
  Future<List<VerseContentVersion>> currVersionList(
    int bookId,
    VerseVersionType verseVersionType,
  ) async {
    return _queryAdapter.queryList(
        'SELECT VerseContentVersion.*  FROM VerseKey JOIN VerseContentVersion ON VerseContentVersion.verseKeyId=VerseKey.id  AND VerseContentVersion.t=?2  AND VerseContentVersion.version=VerseKey.contentVersion WHERE VerseContentVersion.bookId=?1',
        mapper: (Map<String, Object?> row) => VerseContentVersion(classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterKeyId: row['chapterKeyId'] as int, verseKeyId: row['verseKeyId'] as int, t: _verseVersionTypeConverter.decode(row['t'] as int), version: row['version'] as int, reason: _versionReasonConverter.decode(row['reason'] as int), content: row['content'] as String, createTime: _dateTimeConverter.decode(row['createTime'] as int)),
        arguments: [
          bookId,
          _verseVersionTypeConverter.encode(verseVersionType)
        ]);
  }

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseContentVersion WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> deleteByVerseKeyId(int verseKeyId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseContentVersion WHERE verseKeyId=?1',
        arguments: [verseKeyId]);
  }

  @override
  Future<void> insertOrFail(VerseContentVersion entity) async {
    await _verseContentVersionInsertionAdapter.insert(
        entity, OnConflictStrategy.fail);
  }

  @override
  Future<void> insertOrIgnore(VerseContentVersion entity) async {
    await _verseContentVersionInsertionAdapter.insert(
        entity, OnConflictStrategy.ignore);
  }

  @override
  Future<void> insertsOrIgnore(List<VerseContentVersion> entities) async {
    await _verseContentVersionInsertionAdapter.insertList(
        entities, OnConflictStrategy.ignore);
  }
}

class _$VerseDao extends VerseDao {
  _$VerseDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _verseInsertionAdapter = InsertionAdapter(
            database,
            'Verse',
            (Verse item) => <String, Object?>{
                  'verseKeyId': item.verseKeyId,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterKeyId': item.chapterKeyId,
                  'chapterIndex': item.chapterIndex,
                  'verseIndex': item.verseIndex,
                  'sort': item.sort
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Verse> _verseInsertionAdapter;

  @override
  Future<Verse?> one(
    int bookId,
    int chapterIndex,
    int verseIndex,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM Verse WHERE bookId=?1 AND chapterIndex=?2 AND verseIndex=?3',
        mapper: (Map<String, Object?> row) => Verse(verseKeyId: row['verseKeyId'] as int, classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterKeyId: row['chapterKeyId'] as int, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int, sort: row['sort'] as int),
        arguments: [bookId, chapterIndex, verseIndex]);
  }

  @override
  Future<Verse?> last(
    int bookId,
    int minChapterIndex,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM Verse WHERE bookId=?1 AND chapterIndex>=?2 order by chapterIndex,verseIndex limit 1',
        mapper: (Map<String, Object?> row) => Verse(verseKeyId: row['verseKeyId'] as int, classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterKeyId: row['chapterKeyId'] as int, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int, sort: row['sort'] as int),
        arguments: [bookId, minChapterIndex]);
  }

  @override
  Future<List<Verse>> findByMinVerseIndex(
    int bookId,
    int chapterIndex,
    int minVerseIndex,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Verse WHERE bookId=?1 AND chapterIndex=?2 AND verseIndex>=?3',
        mapper: (Map<String, Object?> row) => Verse(verseKeyId: row['verseKeyId'] as int, classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterKeyId: row['chapterKeyId'] as int, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int, sort: row['sort'] as int),
        arguments: [bookId, chapterIndex, minVerseIndex]);
  }

  @override
  Future<void> deleteByMinVerseIndex(
    int bookId,
    int chapterIndex,
    int minVerseIndex,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Verse WHERE bookId=?1 AND chapterIndex=?2 AND verseIndex>=?3',
        arguments: [bookId, chapterIndex, minVerseIndex]);
  }

  @override
  Future<List<Verse>> findByMinChapterIndex(
    int bookId,
    int minChapterIndex,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Verse WHERE bookId=?1 AND chapterIndex>=?2',
        mapper: (Map<String, Object?> row) => Verse(
            verseKeyId: row['verseKeyId'] as int,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterKeyId: row['chapterKeyId'] as int,
            chapterIndex: row['chapterIndex'] as int,
            verseIndex: row['verseIndex'] as int,
            sort: row['sort'] as int),
        arguments: [bookId, minChapterIndex]);
  }

  @override
  Future<void> deleteByMinChapterIndex(
    int bookId,
    int minChapterIndex,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Verse WHERE bookId=?1 AND chapterIndex>=?2',
        arguments: [bookId, minChapterIndex]);
  }

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM Verse WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> deleteByBookId(int bookId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM Verse WHERE Verse.bookId=?1',
        arguments: [bookId]);
  }

  @override
  Future<void> insertOrFail(Verse entity) async {
    await _verseInsertionAdapter.insert(entity, OnConflictStrategy.fail);
  }

  @override
  Future<void> insertListOrFail(List<Verse> entities) async {
    await _verseInsertionAdapter.insertList(entities, OnConflictStrategy.fail);
  }
}

class _$VerseKeyDao extends VerseKeyDao {
  _$VerseKeyDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _verseKeyInsertionAdapter = InsertionAdapter(
            database,
            'VerseKey',
            (VerseKey item) => <String, Object?>{
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterKeyId': item.chapterKeyId,
                  'chapterIndex': item.chapterIndex,
                  'verseIndex': item.verseIndex,
                  'version': item.version,
                  'k': item.k,
                  'content': item.content,
                  'contentVersion': item.contentVersion,
                  'note': item.note,
                  'noteVersion': item.noteVersion
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<VerseKey> _verseKeyInsertionAdapter;

  @override
  Future<VerseKey?> oneById(int id) async {
    return _queryAdapter.query('SELECT * FROM VerseKey where id=?1',
        mapper: (Map<String, Object?> row) => VerseKey(
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterKeyId: row['chapterKeyId'] as int,
            chapterIndex: row['chapterIndex'] as int,
            verseIndex: row['verseIndex'] as int,
            version: row['version'] as int,
            k: row['k'] as String,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int,
            note: row['note'] as String,
            noteVersion: row['noteVersion'] as int,
            id: row['id'] as int?),
        arguments: [id]);
  }

  @override
  Future<int?> count(int chapterKeyId) async {
    return _queryAdapter.query(
        'SELECT count(id) FROM VerseKey where chapterKeyId=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [chapterKeyId]);
  }

  @override
  Future<List<VerseKey>> findByMinVerseIndex(
    int bookId,
    int chapterIndex,
    int minVerseIndex,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM VerseKey WHERE bookId=?1 AND chapterIndex=?2 AND verseIndex>=?3',
        mapper: (Map<String, Object?> row) => VerseKey(classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterKeyId: row['chapterKeyId'] as int, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int, version: row['version'] as int, k: row['k'] as String, content: row['content'] as String, contentVersion: row['contentVersion'] as int, note: row['note'] as String, noteVersion: row['noteVersion'] as int, id: row['id'] as int?),
        arguments: [bookId, chapterIndex, minVerseIndex]);
  }

  @override
  Future<void> deleteByMinVerseIndex(
    int bookId,
    int chapterIndex,
    int minVerseIndex,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseKey WHERE bookId=?1 AND chapterIndex=?2 AND verseIndex>=?3',
        arguments: [bookId, chapterIndex, minVerseIndex]);
  }

  @override
  Future<List<VerseKey>> findByMinChapterIndex(
    int bookId,
    int minChapterIndex,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM VerseKey WHERE bookId=?1 AND chapterIndex>=?2',
        mapper: (Map<String, Object?> row) => VerseKey(
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterKeyId: row['chapterKeyId'] as int,
            chapterIndex: row['chapterIndex'] as int,
            verseIndex: row['verseIndex'] as int,
            version: row['version'] as int,
            k: row['k'] as String,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int,
            note: row['note'] as String,
            noteVersion: row['noteVersion'] as int,
            id: row['id'] as int?),
        arguments: [bookId, minChapterIndex]);
  }

  @override
  Future<void> deleteByMinChapterIndex(
    int bookId,
    int minChapterIndex,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseKey WHERE bookId=?1 AND chapterIndex>=?2',
        arguments: [bookId, minChapterIndex]);
  }

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseKey WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> insertOrFail(VerseKey entity) async {
    await _verseKeyInsertionAdapter.insert(entity, OnConflictStrategy.fail);
  }

  @override
  Future<void> insertListOrFail(List<VerseKey> entities) async {
    await _verseKeyInsertionAdapter.insertList(
        entities, OnConflictStrategy.fail);
  }
}

class _$VerseOverallPrgDao extends VerseOverallPrgDao {
  _$VerseOverallPrgDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _verseOverallPrgInsertionAdapter = InsertionAdapter(
            database,
            'VerseOverallPrg',
            (VerseOverallPrg item) => <String, Object?>{
                  'verseKeyId': item.verseKeyId,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterKeyId': item.chapterKeyId,
                  'next': _dateConverter.encode(item.next),
                  'progress': item.progress
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<VerseOverallPrg> _verseOverallPrgInsertionAdapter;

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseOverallPrg WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> insertOrFail(VerseOverallPrg entity) async {
    await _verseOverallPrgInsertionAdapter.insert(
        entity, OnConflictStrategy.fail);
  }
}

class _$StatsDao extends StatsDao {
  _$StatsDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _timeStatsInsertionAdapter = InsertionAdapter(
            database,
            'TimeStats',
            (TimeStats item) => <String, Object?>{
                  'classroomId': item.classroomId,
                  'createDate': _dateConverter.encode(item.createDate),
                  'createTime': item.createTime,
                  'duration': item.duration
                }),
        _crKvInsertionAdapter = InsertionAdapter(
            database,
            'CrKv',
            (CrKv item) => <String, Object?>{
                  'classroomId': item.classroomId,
                  'k': _crKConverter.encode(item.k),
                  'value': item.value
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<TimeStats> _timeStatsInsertionAdapter;

  final InsertionAdapter<CrKv> _crKvInsertionAdapter;

  @override
  Future<List<VerseStats>> getStatsByDate(
    int classroomId,
    Date date,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM VerseStats WHERE classroomId = ?1 AND createDate = ?2',
        mapper: (Map<String, Object?> row) => VerseStats(
            verseKeyId: row['verseKeyId'] as int,
            type: row['type'] as int,
            createDate: _dateConverter.decode(row['createDate'] as int),
            createTime: row['createTime'] as int,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int),
        arguments: [classroomId, _dateConverter.encode(date)]);
  }

  @override
  Future<List<VerseStats>> getStatsByDateRange(
    int classroomId,
    Date start,
    Date end,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM VerseStats WHERE classroomId = ?1 AND createDate >= ?2 AND createDate <= ?3',
        mapper: (Map<String, Object?> row) => VerseStats(verseKeyId: row['verseKeyId'] as int, type: row['type'] as int, createDate: _dateConverter.decode(row['createDate'] as int), createTime: row['createTime'] as int, classroomId: row['classroomId'] as int, bookId: row['bookId'] as int),
        arguments: [
          classroomId,
          _dateConverter.encode(start),
          _dateConverter.encode(end)
        ]);
  }

  @override
  Future<int?> getCountByDateRange(
    int classroomId,
    Date start,
    Date end,
  ) async {
    return _queryAdapter.query(
        'SELECT COALESCE(COUNT(*), 0) FROM VerseStats WHERE classroomId = ?1 AND createDate >= ?2 AND createDate <= ?3',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [
          classroomId,
          _dateConverter.encode(start),
          _dateConverter.encode(end)
        ]);
  }

  @override
  Future<int?> getCountByType(
    int classroomId,
    int type,
    Date date,
  ) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM VerseStats WHERE classroomId = ?1 AND type = ?2 AND createDate = ?3',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, type, _dateConverter.encode(date)]);
  }

  @override
  Future<List<int>> getDistinctVerseKeyIds(
    int classroomId,
    Date date,
  ) async {
    return _queryAdapter.queryList(
        'SELECT DISTINCT verseKeyId FROM VerseStats WHERE classroomId = ?1 AND createDate = ?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, _dateConverter.encode(date)]);
  }

  @override
  Future<TimeStats?> getTimeStatsByDate(
    int classroomId,
    Date date,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM TimeStats WHERE classroomId = ?1 AND createDate = ?2',
        mapper: (Map<String, Object?> row) => TimeStats(
            row['classroomId'] as int,
            _dateConverter.decode(row['createDate'] as int),
            row['createTime'] as int,
            row['duration'] as int),
        arguments: [classroomId, _dateConverter.encode(date)]);
  }

  @override
  Future<List<TimeStats>> getTimeStatsByDateRange(
    int classroomId,
    Date start,
    Date end,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM TimeStats WHERE classroomId = ?1 AND createDate >= ?2 AND createDate <= ?3',
        mapper: (Map<String, Object?> row) => TimeStats(row['classroomId'] as int, _dateConverter.decode(row['createDate'] as int), row['createTime'] as int, row['duration'] as int),
        arguments: [
          classroomId,
          _dateConverter.encode(start),
          _dateConverter.encode(end)
        ]);
  }

  @override
  Future<int?> getTimeByDateRange(
    int classroomId,
    Date start,
    Date end,
  ) async {
    return _queryAdapter.query(
        'SELECT COALESCE(sum(duration), 0) FROM TimeStats WHERE classroomId = ?1 AND createDate >= ?2 AND createDate <= ?3',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [
          classroomId,
          _dateConverter.encode(start),
          _dateConverter.encode(end)
        ]);
  }

  @override
  Future<void> updateTimeStats(
    int classroomId,
    Date date,
    int time,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE TimeStats set duration=?3+duration WHERE classroomId=?1 AND createDate=?2',
        arguments: [classroomId, _dateConverter.encode(date), time]);
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
  Future<void> insertTimeStats(TimeStats timeStats) async {
    await _timeStatsInsertionAdapter.insert(
        timeStats, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertKv(CrKv kv) async {
    await _crKvInsertionAdapter.insert(kv, OnConflictStrategy.replace);
  }

  @override
  Future<void> tryInsertTimeStats(TimeStats newTimeStats) async {
    if (database is sqflite.Transaction) {
      await super.tryInsertTimeStats(newTimeStats);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.statsDao.tryInsertTimeStats(newTimeStats);
      });
    }
  }

  @override
  Future<List<int>> collectAll() async {
    if (database is sqflite.Transaction) {
      return super.collectAll();
    } else {
      return (database as sqflite.Database)
          .transaction<List<int>>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.statsDao.collectAll();
      });
    }
  }
}

class _$VerseReviewDao extends VerseReviewDao {
  _$VerseReviewDao(
    this.database,
    this.changeListener,
  ) : _queryAdapter = QueryAdapter(database);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseReview WHERE classroomId=?1',
        arguments: [classroomId]);
  }
}

class _$VerseStatsDao extends VerseStatsDao {
  _$VerseStatsDao(
    this.database,
    this.changeListener,
  ) : _queryAdapter = QueryAdapter(database);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseStats WHERE classroomId=?1',
        arguments: [classroomId]);
  }
}

class _$VerseTodayPrgDao extends VerseTodayPrgDao {
  _$VerseTodayPrgDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _verseTodayPrgInsertionAdapter = InsertionAdapter(
            database,
            'VerseTodayPrg',
            (VerseTodayPrg item) => <String, Object?>{
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterKeyId': item.chapterKeyId,
                  'verseKeyId': item.verseKeyId,
                  'time': item.time,
                  'type': item.type,
                  'sort': item.sort,
                  'progress': item.progress,
                  'viewTime': _dateTimeConverter.encode(item.viewTime),
                  'reviewCount': item.reviewCount,
                  'reviewCreateDate':
                      _dateConverter.encode(item.reviewCreateDate),
                  'finish': item.finish ? 1 : 0
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<VerseTodayPrg> _verseTodayPrgInsertionAdapter;

  @override
  Future<VerseTodayPrg?> one(
    int classroomId,
    int verseKeyId,
    int type,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM VerseTodayPrg where classroomId=?1 and verseKeyId=?2 and type=?3',
        mapper: (Map<String, Object?> row) => VerseTodayPrg(classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterKeyId: row['chapterKeyId'] as int, verseKeyId: row['verseKeyId'] as int, time: row['time'] as int, type: row['type'] as int, sort: row['sort'] as int, progress: row['progress'] as int, viewTime: _dateTimeConverter.decode(row['viewTime'] as int), reviewCount: row['reviewCount'] as int, reviewCreateDate: _dateConverter.decode(row['reviewCreateDate'] as int), finish: (row['finish'] as int) != 0, id: row['id'] as int?),
        arguments: [classroomId, verseKeyId, type]);
  }

  @override
  Future<void> delete(int id) async {
    await _queryAdapter.queryNoReturn('DELETE FROM VerseTodayPrg WHERE id=?1',
        arguments: [id]);
  }

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseTodayPrg WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> insertOrFail(VerseTodayPrg entity) async {
    await _verseTodayPrgInsertionAdapter.insert(
        entity, OnConflictStrategy.fail);
  }
}

// ignore_for_file: unused_element
final _kConverter = KConverter();
final _crKConverter = CrKConverter();
final _dateTimeConverter = DateTimeConverter();
final _dateConverter = DateConverter();
final _verseVersionTypeConverter = VerseVersionTypeConverter();
final _versionReasonConverter = VersionReasonConverter();
