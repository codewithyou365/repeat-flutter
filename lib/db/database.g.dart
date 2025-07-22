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

  ClassroomDao? _classroomDaoInstance;

  CrKvDao? _crKvDaoInstance;

  LockDao? _lockDaoInstance;

  GameUserDao? _gameUserDaoInstance;

  GameDao? _gameDaoInstance;

  GameUserInputDao? _gameUserInputDaoInstance;

  KvDao? _kvDaoInstance;

  TimeStatsDao? _timeStatsDaoInstance;

  ScheduleDao? _scheduleDaoInstance;

  VerseContentVersionDao? _verseContentVersionDaoInstance;

  VerseDao? _verseDaoInstance;

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
            'CREATE TABLE IF NOT EXISTS `Book` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `classroomId` INTEGER NOT NULL, `name` TEXT NOT NULL, `desc` TEXT NOT NULL, `enable` INTEGER NOT NULL, `url` TEXT NOT NULL, `content` TEXT NOT NULL, `contentVersion` INTEGER NOT NULL, `sort` INTEGER NOT NULL, `createTime` INTEGER NOT NULL, `updateTime` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `BookContentVersion` (`classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `version` INTEGER NOT NULL, `reason` INTEGER NOT NULL, `content` TEXT NOT NULL, `createTime` INTEGER NOT NULL, PRIMARY KEY (`bookId`, `version`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Chapter` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterIndex` INTEGER NOT NULL, `content` TEXT NOT NULL, `contentVersion` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ChapterContentVersion` (`classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterId` INTEGER NOT NULL, `version` INTEGER NOT NULL, `reason` INTEGER NOT NULL, `content` TEXT NOT NULL, `createTime` INTEGER NOT NULL, PRIMARY KEY (`chapterId`, `version`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Kv` (`k` TEXT NOT NULL, `value` TEXT NOT NULL, PRIMARY KEY (`k`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Classroom` (`id` INTEGER NOT NULL, `name` TEXT NOT NULL, `sort` INTEGER NOT NULL, `hide` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `CrKv` (`classroomId` INTEGER NOT NULL, `k` TEXT NOT NULL, `value` TEXT NOT NULL, PRIMARY KEY (`classroomId`, `k`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Verse` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterId` INTEGER NOT NULL, `chapterIndex` INTEGER NOT NULL, `verseIndex` INTEGER NOT NULL, `sort` INTEGER NOT NULL, `content` TEXT NOT NULL, `contentVersion` INTEGER NOT NULL, `learnDate` INTEGER NOT NULL, `progress` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `VerseContentVersion` (`classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterId` INTEGER NOT NULL, `verseId` INTEGER NOT NULL, `version` INTEGER NOT NULL, `reason` INTEGER NOT NULL, `content` TEXT NOT NULL, `createTime` INTEGER NOT NULL, PRIMARY KEY (`verseId`, `version`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `VerseReview` (`createDate` INTEGER NOT NULL, `verseId` INTEGER NOT NULL, `classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterId` INTEGER NOT NULL, `count` INTEGER NOT NULL, PRIMARY KEY (`createDate`, `verseId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `VerseTodayPrg` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterId` INTEGER NOT NULL, `verseId` INTEGER NOT NULL, `time` INTEGER NOT NULL, `type` INTEGER NOT NULL, `sort` INTEGER NOT NULL, `progress` INTEGER NOT NULL, `viewTime` INTEGER NOT NULL, `reviewCount` INTEGER NOT NULL, `reviewCreateDate` INTEGER NOT NULL, `finish` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `VerseStats` (`verseId` INTEGER NOT NULL, `type` INTEGER NOT NULL, `createDate` INTEGER NOT NULL, `createTime` INTEGER NOT NULL, `classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterId` INTEGER NOT NULL, PRIMARY KEY (`verseId`, `type`, `createDate`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `TimeStats` (`classroomId` INTEGER NOT NULL, `createDate` INTEGER NOT NULL, `createTime` INTEGER NOT NULL, `duration` INTEGER NOT NULL, PRIMARY KEY (`classroomId`, `createDate`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Game` (`id` INTEGER NOT NULL, `time` INTEGER NOT NULL, `verseContent` TEXT NOT NULL, `verseId` INTEGER NOT NULL, `classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterId` INTEGER NOT NULL, `finish` INTEGER NOT NULL, `createTime` INTEGER NOT NULL, `createDate` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `GameUser` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL, `password` TEXT NOT NULL, `nonce` TEXT NOT NULL, `createDate` INTEGER NOT NULL, `token` TEXT NOT NULL, `tokenExpiredDate` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `GameUserInput` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `gameId` INTEGER NOT NULL, `gameUserId` INTEGER NOT NULL, `time` INTEGER NOT NULL, `verseId` INTEGER NOT NULL, `classroomId` INTEGER NOT NULL, `bookId` INTEGER NOT NULL, `chapterId` INTEGER NOT NULL, `input` TEXT NOT NULL, `output` TEXT NOT NULL, `createTime` INTEGER NOT NULL, `createDate` INTEGER NOT NULL)');
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
            'CREATE INDEX `index_BookContentVersion_classroomId` ON `BookContentVersion` (`classroomId`)');
        await database.execute(
            'CREATE INDEX `index_Chapter_classroomId` ON `Chapter` (`classroomId`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Chapter_bookId_chapterIndex` ON `Chapter` (`bookId`, `chapterIndex`)');
        await database.execute(
            'CREATE INDEX `index_ChapterContentVersion_classroomId` ON `ChapterContentVersion` (`classroomId`)');
        await database.execute(
            'CREATE INDEX `index_ChapterContentVersion_bookId` ON `ChapterContentVersion` (`bookId`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Classroom_name` ON `Classroom` (`name`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Classroom_sort` ON `Classroom` (`sort`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Verse_chapterId_verseIndex` ON `Verse` (`chapterId`, `verseIndex`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Verse_classroomId_sort` ON `Verse` (`classroomId`, `sort`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_Verse_bookId_chapterIndex_verseIndex` ON `Verse` (`bookId`, `chapterIndex`, `verseIndex`)');
        await database.execute(
            'CREATE INDEX `index_VerseContentVersion_classroomId` ON `VerseContentVersion` (`classroomId`)');
        await database.execute(
            'CREATE INDEX `index_VerseContentVersion_bookId` ON `VerseContentVersion` (`bookId`)');
        await database.execute(
            'CREATE INDEX `index_VerseContentVersion_chapterId` ON `VerseContentVersion` (`chapterId`)');
        await database.execute(
            'CREATE INDEX `index_VerseReview_bookId` ON `VerseReview` (`bookId`)');
        await database.execute(
            'CREATE INDEX `index_VerseReview_classroomId_createDate` ON `VerseReview` (`classroomId`, `createDate`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_VerseTodayPrg_verseId_type` ON `VerseTodayPrg` (`verseId`, `type`)');
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
        await database
            .execute('CREATE INDEX `index_Game_bookId` ON `Game` (`bookId`)');
        await database
            .execute('CREATE INDEX `index_Game_verseId` ON `Game` (`verseId`)');
        await database.execute(
            'CREATE INDEX `index_Game_createDate` ON `Game` (`createDate`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_GameUser_name` ON `GameUser` (`name`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_GameUser_token` ON `GameUser` (`token`)');
        await database.execute(
            'CREATE INDEX `index_GameUserInput_classroomId` ON `GameUserInput` (`classroomId`)');
        await database.execute(
            'CREATE INDEX `index_GameUserInput_bookId` ON `GameUserInput` (`bookId`)');
        await database.execute(
            'CREATE INDEX `index_GameUserInput_chapterId` ON `GameUserInput` (`chapterId`)');
        await database.execute(
            'CREATE INDEX `index_GameUserInput_verseId` ON `GameUserInput` (`verseId`)');
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
  Future<void> deleteByBookId(int bookId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM BookContentVersion WHERE bookId=?1',
        arguments: [bookId]);
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
                  'enable': item.enable ? 1 : 0,
                  'url': item.url,
                  'content': item.content,
                  'contentVersion': item.contentVersion,
                  'sort': item.sort,
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
        'SELECT id bookId,classroomId,name,sort,content bookContent,contentVersion bookContentVersion FROM Book where classroomId=?1 and enable=true ORDER BY sort',
        mapper: (Map<String, Object?> row) => BookShow(bookId: row['bookId'] as int, classroomId: row['classroomId'] as int, name: row['name'] as String, sort: row['sort'] as int, bookContent: row['bookContent'] as String, bookContentVersion: row['bookContentVersion'] as int),
        arguments: [classroomId]);
  }

  @override
  Future<List<Book>> getAll(int classroomId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Book where classroomId=?1 ORDER BY sort',
        mapper: (Map<String, Object?> row) => Book(
            id: row['id'] as int?,
            classroomId: row['classroomId'] as int,
            name: row['name'] as String,
            desc: row['desc'] as String,
            enable: (row['enable'] as int) != 0,
            url: row['url'] as String,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int,
            sort: row['sort'] as int,
            createTime: row['createTime'] as int,
            updateTime: row['updateTime'] as int),
        arguments: [classroomId]);
  }

  @override
  Future<List<Book>> getByEnable(
    int classroomId,
    bool enable,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Book where classroomId=?1 and enable=?2 ORDER BY sort',
        mapper: (Map<String, Object?> row) => Book(
            id: row['id'] as int?,
            classroomId: row['classroomId'] as int,
            name: row['name'] as String,
            desc: row['desc'] as String,
            enable: (row['enable'] as int) != 0,
            url: row['url'] as String,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int,
            sort: row['sort'] as int,
            createTime: row['createTime'] as int,
            updateTime: row['updateTime'] as int),
        arguments: [classroomId, enable ? 1 : 0]);
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
            enable: (row['enable'] as int) != 0,
            url: row['url'] as String,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int,
            sort: row['sort'] as int,
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
            enable: (row['enable'] as int) != 0,
            url: row['url'] as String,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int,
            sort: row['sort'] as int,
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
  Future<void> updateBookContentVersionAndEnable(
    int id,
    String content,
    int contentVersion,
    bool enable,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Book set content=?2,contentVersion=?3,enable=?4 WHERE Book.id=?1',
        arguments: [id, content, contentVersion, enable ? 1 : 0]);
  }

  @override
  Future<void> updateBookContentVersionAndStateAndUrl(
    int id,
    String content,
    int contentVersion,
    bool enable,
    String url,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Book set content=?2,contentVersion=?3,enable=?4,url=?5 WHERE Book.id=?1',
        arguments: [id, content, contentVersion, enable ? 1 : 0, url]);
  }

  @override
  Future<void> updateEnable(
    int id,
    bool enable,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Book set enable=?2 WHERE Book.id=?1',
        arguments: [id, enable ? 1 : 0]);
  }

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Book WHERE Book.classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> deleteById(int bookId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM Book WHERE Book.id=?1',
        arguments: [bookId]);
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

  @override
  Future<void> create(
    int bookId,
    String content,
  ) async {
    if (database is sqflite.Transaction) {
      await super.create(bookId, content);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.bookDao.create(bookId, content);
      });
    }
  }

  @override
  Future<void> import(
    Book book,
    List<Chapter> chapters,
    List<Verse> verses,
  ) async {
    if (database is sqflite.Transaction) {
      await super.import(book, chapters, verses);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.bookDao.import(book, chapters, verses);
      });
    }
  }

  @override
  Future<void> reimport(
    Book book,
    List<Chapter> insertChapters,
    List<Chapter> updateChapters,
    List<Verse> insertVerses,
    List<Verse> updateVerses,
  ) async {
    if (database is sqflite.Transaction) {
      await super.reimport(
          book, insertChapters, updateChapters, insertVerses, updateVerses);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.bookDao.reimport(
            book, insertChapters, updateChapters, insertVerses, updateVerses);
      });
    }
  }

  @override
  Future<void> deleteAll(int bookId) async {
    if (database is sqflite.Transaction) {
      await super.deleteAll(bookId);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.bookDao.deleteAll(bookId);
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
                  'chapterId': item.chapterId,
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
  Future<List<ChapterContentVersion>> list(int chapterId) async {
    return _queryAdapter.queryList(
        'SELECT *  FROM ChapterContentVersion WHERE chapterId=?1',
        mapper: (Map<String, Object?> row) => ChapterContentVersion(
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterId: row['chapterId'] as int,
            version: row['version'] as int,
            reason: _versionReasonConverter.decode(row['reason'] as int),
            content: row['content'] as String,
            createTime: _dateTimeConverter.decode(row['createTime'] as int)),
        arguments: [chapterId]);
  }

  @override
  Future<void> remainByChapterIds(List<int> chapterIds) async {
    const offset = 1;
    final _sqliteVariablesForChapterIds =
        Iterable<String>.generate(chapterIds.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'DELETE FROM ChapterContentVersion  WHERE chapterId not in (' +
            _sqliteVariablesForChapterIds +
            ')',
        arguments: [...chapterIds]);
  }

  @override
  Future<List<ChapterContentVersion>> currVersionList(int bookId) async {
    return _queryAdapter.queryList(
        'SELECT c.* FROM ChapterContentVersion c   INNER JOIN (     SELECT chapterId, MAX(version) AS max_version     FROM ChapterContentVersion     WHERE bookId = ?1     GROUP BY chapterId   ) sub   ON c.chapterId = sub.chapterId AND c.version = sub.max_version',
        mapper: (Map<String, Object?> row) => ChapterContentVersion(classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterId: row['chapterId'] as int, version: row['version'] as int, reason: _versionReasonConverter.decode(row['reason'] as int), content: row['content'] as String, createTime: _dateTimeConverter.decode(row['createTime'] as int)),
        arguments: [bookId]);
  }

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM ChapterContentVersion WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> deleteByBookId(int bookId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM ChapterContentVersion WHERE bookId=?1',
        arguments: [bookId]);
  }

  @override
  Future<void> deleteByChapterId(int chapterId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM ChapterContentVersion WHERE chapterId=?1',
        arguments: [chapterId]);
  }

  @override
  Future<void> insertOrFail(List<ChapterContentVersion> entities) async {
    await _chapterContentVersionInsertionAdapter.insertList(
        entities, OnConflictStrategy.fail);
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
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterIndex': item.chapterIndex,
                  'content': item.content,
                  'contentVersion': item.contentVersion
                }),
        _chapterUpdateAdapter = UpdateAdapter(
            database,
            'Chapter',
            ['id'],
            (Chapter item) => <String, Object?>{
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterIndex': item.chapterIndex,
                  'content': item.content,
                  'contentVersion': item.contentVersion
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Chapter> _chapterInsertionAdapter;

  final UpdateAdapter<Chapter> _chapterUpdateAdapter;

  @override
  Future<List<ChapterShow>> getAllChapter(int classroomId) async {
    return _queryAdapter.queryList(
        'SELECT Chapter.id chapterId,Book.id bookId,Book.name bookName,Book.sort bookSort,Chapter.content chapterContent,Chapter.contentVersion chapterContentVersion,Chapter.chapterIndex FROM Chapter JOIN Book ON Book.id=Chapter.bookId AND Book.enable=true WHERE Chapter.classroomId=?1 ORDER BY Chapter.bookId,Chapter.chapterIndex',
        mapper: (Map<String, Object?> row) => ChapterShow(chapterId: row['chapterId'] as int, bookId: row['bookId'] as int, bookName: row['bookName'] as String, bookSort: row['bookSort'] as int, chapterContent: row['chapterContent'] as String, chapterContentVersion: row['chapterContentVersion'] as int, chapterIndex: row['chapterIndex'] as int),
        arguments: [classroomId]);
  }

  @override
  Future<void> syncContentVersion(int bookId) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Chapter  JOIN (  SELECT chapterId,max(version) version FROM ChapterContentVersion  WHERE bookId=?1  GROUP BY chapterId) ChapterContentMaxVersion on ChapterContentMaxVersion.chapterId=Chapter.id set Chapter.contentVersion = ChapterContentMaxVersion.version WHERE Chapter.bookId = ?1',
        arguments: [bookId]);
  }

  @override
  Future<List<Chapter>> findByBookId(int bookId) async {
    return _queryAdapter.queryList('SELECT * FROM Chapter WHERE bookId=?1',
        mapper: (Map<String, Object?> row) => Chapter(
            id: row['id'] as int?,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterIndex: row['chapterIndex'] as int,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int),
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
            id: row['id'] as int?,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterIndex: row['chapterIndex'] as int,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int),
        arguments: [bookId, chapterIndex]);
  }

  @override
  Future<Chapter?> getById(int chapterId) async {
    return _queryAdapter.query('SELECT * FROM Chapter WHERE id=?1',
        mapper: (Map<String, Object?> row) => Chapter(
            id: row['id'] as int?,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterIndex: row['chapterIndex'] as int,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int),
        arguments: [chapterId]);
  }

  @override
  Future<int?> count(int bookId) async {
    return _queryAdapter.query('SELECT count(1) FROM Chapter WHERE bookId=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [bookId]);
  }

  @override
  Future<int?> countByIds(List<int> ids) async {
    const offset = 1;
    final _sqliteVariablesForIds =
        Iterable<String>.generate(ids.length, (i) => '?${i + offset}')
            .join(',');
    return _queryAdapter.query(
        'SELECT count(1) FROM Chapter WHERE id in (' +
            _sqliteVariablesForIds +
            ')',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [...ids]);
  }

  @override
  Future<List<Chapter>> findByMinChapterIndex(
    int bookId,
    int minChapterIndex,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Chapter WHERE bookId=?1 AND chapterIndex>=?2 ORDER BY chapterIndex',
        mapper: (Map<String, Object?> row) => Chapter(id: row['id'] as int?, classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterIndex: row['chapterIndex'] as int, content: row['content'] as String, contentVersion: row['contentVersion'] as int),
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
  Future<void> updateKeyAndContent(
    int id,
    String content,
    int contentVersion,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Chapter set content=?2,contentVersion=?3 WHERE id=?1',
        arguments: [id, content, contentVersion]);
  }

  @override
  Future<void> deleteByBookId(int bookId) async {
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
  Future<void> insertOrFail(List<Chapter> entities) async {
    await _chapterInsertionAdapter.insertList(
        entities, OnConflictStrategy.fail);
  }

  @override
  Future<void> updateOrFail(List<Chapter> entities) async {
    await _chapterUpdateAdapter.updateList(entities, OnConflictStrategy.fail);
  }

  @override
  Future<bool> deleteChapter(
    int chapterId,
    Rx<Chapter> out,
  ) async {
    if (database is sqflite.Transaction) {
      return super.deleteChapter(chapterId, out);
    } else {
      return (database as sqflite.Database)
          .transaction<bool>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.chapterDao.deleteChapter(chapterId, out);
      });
    }
  }

  @override
  Future<bool> addChapter(
    ChapterShow chapterShow,
    int chapterIndex,
    Rx<Chapter> out,
  ) async {
    if (database is sqflite.Transaction) {
      return super.addChapter(chapterShow, chapterIndex, out);
    } else {
      return (database as sqflite.Database)
          .transaction<bool>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.chapterDao
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
        return transactionDatabase.chapterDao.addFirstChapter(bookId);
      });
    }
  }

  @override
  Future<void> updateChapterContent(
    int chapterId,
    String content,
  ) async {
    if (database is sqflite.Transaction) {
      await super.updateChapterContent(chapterId, content);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.chapterDao
            .updateChapterContent(chapterId, content);
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
                  'verseId': item.verseId,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterId': item.chapterId,
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
                  'verseId': item.verseId,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterId': item.chapterId,
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
            verseId: row['verseId'] as int,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterId: row['chapterId'] as int,
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
            verseId: row['verseId'] as int,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterId: row['chapterId'] as int,
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
        mapper: (Map<String, Object?> row) => GameUserInput(gameId: row['gameId'] as int, gameUserId: row['gameUserId'] as int, time: row['time'] as int, verseId: row['verseId'] as int, classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterId: row['chapterId'] as int, input: row['input'] as String, output: row['output'] as String, createTime: row['createTime'] as int, createDate: _dateConverter.decode(row['createDate'] as int), id: row['id'] as int?),
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
        mapper: (Map<String, Object?> row) => GameUserInput(gameId: row['gameId'] as int, gameUserId: row['gameUserId'] as int, time: row['time'] as int, verseId: row['verseId'] as int, classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterId: row['chapterId'] as int, input: row['input'] as String, output: row['output'] as String, createTime: row['createTime'] as int, createDate: _dateConverter.decode(row['createDate'] as int), id: row['id'] as int?),
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
  Future<void> deleteByBookId(int bookId) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM Game WHERE bookId=?1', arguments: [bookId]);
  }

  @override
  Future<void> deleteByChapterId(int chapterId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM Game WHERE chapterId=?1',
        arguments: [chapterId]);
  }

  @override
  Future<void> deleteByVerseId(int verseId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM Game WHERE verseId=?1',
        arguments: [verseId]);
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

  @override
  Future<void> deleteByBookId(int bookId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM GameUserInput WHERE bookId=?1',
        arguments: [bookId]);
  }

  @override
  Future<void> deleteByChapterId(int chapterId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM GameUserInput WHERE chapterId=?1',
        arguments: [chapterId]);
  }

  @override
  Future<void> deleteByVerseId(int verseId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM GameUserInput WHERE verseId=?1',
        arguments: [verseId]);
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

class _$TimeStatsDao extends TimeStatsDao {
  _$TimeStatsDao(
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
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<TimeStats> _timeStatsInsertionAdapter;

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM TimeStats WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<TimeStats?> getByDate(
    int classroomId,
    Date date,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM TimeStats WHERE classroomId = ?1 AND createDate = ?2',
        mapper: (Map<String, Object?> row) => TimeStats(
            classroomId: row['classroomId'] as int,
            createDate: _dateConverter.decode(row['createDate'] as int),
            createTime: row['createTime'] as int,
            duration: row['duration'] as int),
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
        mapper: (Map<String, Object?> row) => TimeStats(classroomId: row['classroomId'] as int, createDate: _dateConverter.decode(row['createDate'] as int), createTime: row['createTime'] as int, duration: row['duration'] as int),
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
  Future<void> update(
    int classroomId,
    Date date,
    int time,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE TimeStats set duration=?3+duration WHERE classroomId=?1 AND createDate=?2',
        arguments: [classroomId, _dateConverter.encode(date), time]);
  }

  @override
  Future<void> insertOrReplace(TimeStats timeStats) async {
    await _timeStatsInsertionAdapter.insert(
        timeStats, OnConflictStrategy.replace);
  }

  @override
  Future<void> tryInsert(TimeStats newTimeStats) async {
    if (database is sqflite.Transaction) {
      await super.tryInsert(newTimeStats);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.timeStatsDao.tryInsert(newTimeStats);
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
        _verseTodayPrgInsertionAdapter = InsertionAdapter(
            database,
            'VerseTodayPrg',
            (VerseTodayPrg item) => <String, Object?>{
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterId': item.chapterId,
                  'verseId': item.verseId,
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
                  'verseId': item.verseId,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterId': item.chapterId,
                  'count': item.count
                }),
        _verseInsertionAdapter = InsertionAdapter(
            database,
            'Verse',
            (Verse item) => <String, Object?>{
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterId': item.chapterId,
                  'chapterIndex': item.chapterIndex,
                  'verseIndex': item.verseIndex,
                  'sort': item.sort,
                  'content': item.content,
                  'contentVersion': item.contentVersion,
                  'learnDate': _dateConverter.encode(item.learnDate),
                  'progress': item.progress
                }),
        _verseStatsInsertionAdapter = InsertionAdapter(
            database,
            'VerseStats',
            (VerseStats item) => <String, Object?>{
                  'verseId': item.verseId,
                  'type': item.type,
                  'createDate': _dateConverter.encode(item.createDate),
                  'createTime': item.createTime,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterId': item.chapterId
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

  final InsertionAdapter<Verse> _verseInsertionAdapter;

  final InsertionAdapter<VerseStats> _verseStatsInsertionAdapter;

  final DeletionAdapter<CrKv> _crKvDeletionAdapter;

  @override
  Future<void> forUpdate() async {
    await _queryAdapter
        .queryNoReturn('SELECT * FROM Lock where id=1 for update');
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
            chapterId: row['chapterId'] as int,
            verseId: row['verseId'] as int,
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
    int verseId,
    int type,
    int progress,
    DateTime viewTime,
    bool finish,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE VerseTodayPrg SET progress=?3,viewTime=?4,finish=?5 WHERE verseId=?1 and type=?2',
        arguments: [
          verseId,
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
        'SELECT IFNULL(MIN(VerseReview.createDate),-1) FROM VerseReview JOIN Verse ON Verse.id=VerseReview.verseId WHERE VerseReview.classroomId=?1 AND VerseReview.count=?2 and VerseReview.createDate<=?3 order by VerseReview.createDate',
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
        'SELECT VerseReview.classroomId,Verse.bookId,Verse.chapterId,VerseReview.verseId,0 time,0 type,Verse.sort,0 progress,0 viewTime,VerseReview.count reviewCount,VerseReview.createDate reviewCreateDate,0 finish FROM VerseReview JOIN Verse ON Verse.id=VerseReview.verseId WHERE VerseReview.classroomId=?1 AND VerseReview.count=?2 AND VerseReview.createDate=?3 ORDER BY Verse.sort',
        mapper: (Map<String, Object?> row) => VerseTodayPrg(classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterId: row['chapterId'] as int, verseId: row['verseId'] as int, time: row['time'] as int, type: row['type'] as int, sort: row['sort'] as int, progress: row['progress'] as int, viewTime: _dateTimeConverter.decode(row['viewTime'] as int), reviewCount: row['reviewCount'] as int, reviewCreateDate: _dateConverter.decode(row['reviewCreateDate'] as int), finish: (row['finish'] as int) != 0, id: row['id'] as int?),
        arguments: [
          classroomId,
          reviewCount,
          _dateConverter.encode(startDate)
        ]);
  }

  @override
  Future<List<VerseTodayPrg>> scheduleLearn(
    int minProgress,
    Date now,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ( SELECT Verse.classroomId,Verse.bookId,Verse.chapterId,Verse.id verseId,0 time,0 type,Verse.sort,Verse.progress progress,0 viewTime,0 reviewCount,0 reviewCreateDate,0 finish FROM Verse WHERE Verse.learnDate<=?2  AND Verse.progress>=?1 ORDER BY Verse.progress,Verse.sort ) Verse order by Verse.sort',
        mapper: (Map<String, Object?> row) => VerseTodayPrg(classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterId: row['chapterId'] as int, verseId: row['verseId'] as int, time: row['time'] as int, type: row['type'] as int, sort: row['sort'] as int, progress: row['progress'] as int, viewTime: _dateTimeConverter.decode(row['viewTime'] as int), reviewCount: row['reviewCount'] as int, reviewCreateDate: _dateConverter.decode(row['reviewCreateDate'] as int), finish: (row['finish'] as int) != 0, id: row['id'] as int?),
        arguments: [minProgress, _dateConverter.encode(now)]);
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
        'SELECT Verse.classroomId,Verse.bookId,Verse.chapterId,Verse.id verseId,0 time,0 type,Verse.sort,0 progress,0 viewTime,0 reviewCount,1 reviewCreateDate,0 finish FROM Verse WHERE Verse.classroomId=?1 AND Verse.sort>=(  SELECT Verse.sort FROM Verse  WHERE Verse.bookId=?2  AND Verse.chapterIndex=?3  AND Verse.verseIndex=?4) ORDER BY Verse.sort limit ?5',
        mapper: (Map<String, Object?> row) => VerseTodayPrg(classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterId: row['chapterId'] as int, verseId: row['verseId'] as int, time: row['time'] as int, type: row['type'] as int, sort: row['sort'] as int, progress: row['progress'] as int, viewTime: _dateTimeConverter.decode(row['viewTime'] as int), reviewCount: row['reviewCount'] as int, reviewCreateDate: _dateConverter.decode(row['reviewCreateDate'] as int), finish: (row['finish'] as int) != 0, id: row['id'] as int?),
        arguments: [classroomId, bookId, chapterIndex, verseIndex, limit]);
  }

  @override
  Future<void> setPrgAndLearnDate4Sop(
    int verseId,
    int progress,
    Date learnDate,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Verse SET progress=?2,learnDate=?3 WHERE id=?1',
        arguments: [verseId, progress, _dateConverter.encode(learnDate)]);
  }

  @override
  Future<void> setPrg4Sop(
    int verseId,
    int progress,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Verse SET progress=?2 WHERE id=?1',
        arguments: [verseId, progress]);
  }

  @override
  Future<int?> getVerseProgress(int verseId) async {
    return _queryAdapter.query('SELECT progress FROM Verse WHERE id=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [verseId]);
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
        'SELECT VerseReview.*,Book.name contentName,Verse.chapterIndex,Verse.verseIndex FROM VerseReview JOIN Verse ON Verse.id=VerseReview.verseId JOIN Book ON Book.id=VerseReview.bookId WHERE VerseReview.classroomId=?1 AND VerseReview.createDate>=?2 AND VerseReview.createDate<=?3 ORDER BY VerseReview.createDate desc,Verse.sort asc',
        mapper: (Map<String, Object?> row) => VerseReviewWithKey(createDate: _dateConverter.decode(row['createDate'] as int), verseId: row['verseId'] as int, classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterId: row['chapterId'] as int, count: row['count'] as int, contentName: row['contentName'] as String, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int),
        arguments: [
          classroomId,
          _dateConverter.encode(start),
          _dateConverter.encode(end)
        ]);
  }

  @override
  Future<void> setVerseReviewCount(
    Date createDate,
    int verseId,
    int count,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE VerseReview SET count=?3 WHERE createDate=?1 and `verseId`=?2',
        arguments: [_dateConverter.encode(createDate), verseId, count]);
  }

  @override
  Future<int?> getPrevVerseKeyIdWithOffset(
    int classroomId,
    int verseId,
    int offset,
  ) async {
    return _queryAdapter.query(
        'SELECT LimitVerse.verseId FROM (SELECT sort,id verseId  FROM Verse  WHERE classroomId=?1  AND sort<(SELECT Verse.sort FROM Verse WHERE Verse.id=?2)  ORDER BY sort desc  LIMIT ?3) LimitVerse  ORDER BY LimitVerse.sort LIMIT 1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, verseId, offset]);
  }

  @override
  Future<int?> getNextVerseKeyIdWithOffset(
    int classroomId,
    int verseId,
    int offset,
  ) async {
    return _queryAdapter.query(
        'SELECT LimitVerse.verseId FROM (SELECT sort,id verseId  FROM Verse  WHERE classroomId=?1  AND sort>(SELECT Verse.sort FROM Verse WHERE Verse.id=?2)  ORDER BY sort  LIMIT ?3) LimitVerse  ORDER BY LimitVerse.sort desc LIMIT 1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, verseId, offset]);
  }

  @override
  Future<List<VerseShow>> getAllVerse(int classroomId) async {
    return _queryAdapter.queryList(
        'SELECT Verse.id verseId,Book.id bookId,Book.name bookName,Book.sort bookSort,Verse.content verseContent,Verse.contentVersion verseContentVersion,Verse.chapterId,Verse.chapterIndex,Verse.verseIndex,Verse.learnDate,Verse.progress FROM Verse JOIN Book ON Book.id=Verse.bookId AND Book.enable=true WHERE Verse.classroomId=?1',
        mapper: (Map<String, Object?> row) => VerseShow(verseId: row['verseId'] as int, bookId: row['bookId'] as int, bookName: row['bookName'] as String, bookSort: row['bookSort'] as int, verseContent: row['verseContent'] as String, verseContentVersion: row['verseContentVersion'] as int, chapterId: row['chapterId'] as int, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int, learnDate: _dateConverter.decode(row['learnDate'] as int), progress: row['progress'] as int),
        arguments: [classroomId]);
  }

  @override
  Future<List<VerseShow>> getVerseByChapterIndex(
    int bookId,
    int chapterIndex,
  ) async {
    return _queryAdapter.queryList(
        'SELECT Verse.id verseId,Book.id bookId,Book.name bookName,Book.sort bookSort,Verse.content verseContent,Verse.contentVersion verseContentVersion,Verse.chapterId,Verse.chapterIndex,Verse.verseIndex,Verse.learnDate,Verse.progress FROM Verse JOIN Book ON Book.id=?1 AND Book.enable=true WHERE Verse.bookId=?1  AND Verse.chapterIndex=?2',
        mapper: (Map<String, Object?> row) => VerseShow(verseId: row['verseId'] as int, bookId: row['bookId'] as int, bookName: row['bookName'] as String, bookSort: row['bookSort'] as int, verseContent: row['verseContent'] as String, verseContentVersion: row['verseContentVersion'] as int, chapterId: row['chapterId'] as int, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int, learnDate: _dateConverter.decode(row['learnDate'] as int), progress: row['progress'] as int),
        arguments: [bookId, chapterIndex]);
  }

  @override
  Future<List<VerseShow>> getVerseByMinChapterIndex(
    int bookId,
    int minChapterIndex,
  ) async {
    return _queryAdapter.queryList(
        'SELECT Verse.id verseId,Book.id bookId,Book.name bookName,Book.sort bookSort,Verse.content verseContent,Verse.contentVersion verseContentVersion,Verse.chapterId,Verse.chapterIndex,Verse.verseIndex,Verse.learnDate,Verse.progress FROM Verse JOIN Book ON Book.id=Verse.bookId AND Book.enable=true WHERE Verse.bookId=?1  AND Verse.chapterIndex>=?2',
        mapper: (Map<String, Object?> row) => VerseShow(verseId: row['verseId'] as int, bookId: row['bookId'] as int, bookName: row['bookName'] as String, bookSort: row['bookSort'] as int, verseContent: row['verseContent'] as String, verseContentVersion: row['verseContentVersion'] as int, chapterId: row['chapterId'] as int, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int, learnDate: _dateConverter.decode(row['learnDate'] as int), progress: row['progress'] as int),
        arguments: [bookId, minChapterIndex]);
  }

  @override
  Future<void> deleteVerse(int verseId) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM Verse WHERE id=?1', arguments: [verseId]);
  }

  @override
  Future<void> deleteVerseReview(int verseId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseReview WHERE verseId=?1',
        arguments: [verseId]);
  }

  @override
  Future<void> deleteVerseTodayPrg(int verseId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseTodayPrg WHERE verseId=?1',
        arguments: [verseId]);
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
  Future<void> insertVerses(List<Verse> entities) async {
    await _verseInsertionAdapter.insertList(
        entities, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertVerseStats(VerseStats stats) async {
    await _verseStatsInsertionAdapter.insert(stats, OnConflictStrategy.replace);
  }

  @override
  Future<void> deleteKv(CrKv kv) async {
    await _crKvDeletionAdapter.delete(kv);
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
    int verseId,
    int progress,
    int nextDayValue,
  ) async {
    if (database is sqflite.Transaction) {
      await super.jumpDirectly(verseId, progress, nextDayValue);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        await transactionDatabase.scheduleDao
            .jumpDirectly(verseId, progress, nextDayValue);
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
                  'chapterId': item.chapterId,
                  'verseId': item.verseId,
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
  Future<List<VerseContentVersion>> list(int verseId) async {
    return _queryAdapter.queryList(
        'SELECT *  FROM VerseContentVersion WHERE verseId=?1',
        mapper: (Map<String, Object?> row) => VerseContentVersion(
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterId: row['chapterId'] as int,
            verseId: row['verseId'] as int,
            version: row['version'] as int,
            reason: _versionReasonConverter.decode(row['reason'] as int),
            content: row['content'] as String,
            createTime: _dateTimeConverter.decode(row['createTime'] as int)),
        arguments: [verseId]);
  }

  @override
  Future<List<VerseContentVersion>> currVersionList(int bookId) async {
    return _queryAdapter.queryList(
        'SELECT VerseContentVersion.*  FROM VerseKey JOIN VerseContentVersion ON VerseContentVersion.verseId=VerseKey.id  AND VerseContentVersion.version=VerseKey.contentVersion WHERE VerseContentVersion.bookId=?1',
        mapper: (Map<String, Object?> row) => VerseContentVersion(classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterId: row['chapterId'] as int, verseId: row['verseId'] as int, version: row['version'] as int, reason: _versionReasonConverter.decode(row['reason'] as int), content: row['content'] as String, createTime: _dateTimeConverter.decode(row['createTime'] as int)),
        arguments: [bookId]);
  }

  @override
  Future<void> deleteByClassroomId(int classroomId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseContentVersion WHERE classroomId=?1',
        arguments: [classroomId]);
  }

  @override
  Future<void> deleteByBookId(int bookId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseContentVersion WHERE bookId=?1',
        arguments: [bookId]);
  }

  @override
  Future<void> deleteByChapterId(int chapterId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseContentVersion WHERE chapterId=?1',
        arguments: [chapterId]);
  }

  @override
  Future<void> deleteByVerseId(int verseId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseContentVersion WHERE verseId=?1',
        arguments: [verseId]);
  }

  @override
  Future<void> insertOrFail(VerseContentVersion entity) async {
    await _verseContentVersionInsertionAdapter.insert(
        entity, OnConflictStrategy.fail);
  }

  @override
  Future<void> insertsOrFail(List<VerseContentVersion> entities) async {
    await _verseContentVersionInsertionAdapter.insertList(
        entities, OnConflictStrategy.fail);
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
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterId': item.chapterId,
                  'chapterIndex': item.chapterIndex,
                  'verseIndex': item.verseIndex,
                  'sort': item.sort,
                  'content': item.content,
                  'contentVersion': item.contentVersion,
                  'learnDate': _dateConverter.encode(item.learnDate),
                  'progress': item.progress
                }),
        _verseUpdateAdapter = UpdateAdapter(
            database,
            'Verse',
            ['id'],
            (Verse item) => <String, Object?>{
                  'id': item.id,
                  'classroomId': item.classroomId,
                  'bookId': item.bookId,
                  'chapterId': item.chapterId,
                  'chapterIndex': item.chapterIndex,
                  'verseIndex': item.verseIndex,
                  'sort': item.sort,
                  'content': item.content,
                  'contentVersion': item.contentVersion,
                  'learnDate': _dateConverter.encode(item.learnDate),
                  'progress': item.progress
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Verse> _verseInsertionAdapter;

  final UpdateAdapter<Verse> _verseUpdateAdapter;

  @override
  Future<Verse?> getById(int id) async {
    return _queryAdapter.query('SELECT * FROM Verse where id=?1',
        mapper: (Map<String, Object?> row) => Verse(
            id: row['id'] as int?,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterId: row['chapterId'] as int,
            chapterIndex: row['chapterIndex'] as int,
            verseIndex: row['verseIndex'] as int,
            sort: row['sort'] as int,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int,
            learnDate: _dateConverter.decode(row['learnDate'] as int),
            progress: row['progress'] as int),
        arguments: [id]);
  }

  @override
  Future<List<Verse>> findByBookId(int bookId) async {
    return _queryAdapter.queryList('SELECT * FROM Verse where bookId=?1',
        mapper: (Map<String, Object?> row) => Verse(
            id: row['id'] as int?,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterId: row['chapterId'] as int,
            chapterIndex: row['chapterIndex'] as int,
            verseIndex: row['verseIndex'] as int,
            sort: row['sort'] as int,
            content: row['content'] as String,
            contentVersion: row['contentVersion'] as int,
            learnDate: _dateConverter.decode(row['learnDate'] as int),
            progress: row['progress'] as int),
        arguments: [bookId]);
  }

  @override
  Future<Verse?> getByIndex(
    int bookId,
    int chapterIndex,
    int verseIndex,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM Verse WHERE bookId=?1 AND chapterIndex=?2 AND verseIndex=?3',
        mapper: (Map<String, Object?> row) => Verse(id: row['id'] as int?, classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterId: row['chapterId'] as int, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int, sort: row['sort'] as int, content: row['content'] as String, contentVersion: row['contentVersion'] as int, learnDate: _dateConverter.decode(row['learnDate'] as int), progress: row['progress'] as int),
        arguments: [bookId, chapterIndex, verseIndex]);
  }

  @override
  Future<Verse?> last(
    int bookId,
    int minChapterIndex,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM Verse WHERE bookId=?1 AND chapterIndex>=?2 order by chapterIndex,verseIndex limit 1',
        mapper: (Map<String, Object?> row) => Verse(id: row['id'] as int?, classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterId: row['chapterId'] as int, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int, sort: row['sort'] as int, content: row['content'] as String, contentVersion: row['contentVersion'] as int, learnDate: _dateConverter.decode(row['learnDate'] as int), progress: row['progress'] as int),
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
        mapper: (Map<String, Object?> row) => Verse(id: row['id'] as int?, classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterId: row['chapterId'] as int, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int, sort: row['sort'] as int, content: row['content'] as String, contentVersion: row['contentVersion'] as int, learnDate: _dateConverter.decode(row['learnDate'] as int), progress: row['progress'] as int),
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
        'SELECT * FROM Verse WHERE bookId=?1 AND chapterIndex>=?2 order by chapterIndex,verseIndex',
        mapper: (Map<String, Object?> row) => Verse(id: row['id'] as int?, classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterId: row['chapterId'] as int, chapterIndex: row['chapterIndex'] as int, verseIndex: row['verseIndex'] as int, sort: row['sort'] as int, content: row['content'] as String, contentVersion: row['contentVersion'] as int, learnDate: _dateConverter.decode(row['learnDate'] as int), progress: row['progress'] as int),
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
  Future<void> deleteByChapterKeyId(int chapterId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM Verse WHERE chapterId=?1',
        arguments: [chapterId]);
  }

  @override
  Future<int?> countByIds(List<int> ids) async {
    const offset = 1;
    final _sqliteVariablesForIds =
        Iterable<String>.generate(ids.length, (i) => '?${i + offset}')
            .join(',');
    return _queryAdapter.query(
        'SELECT count(1) FROM Verse WHERE id in (' +
            _sqliteVariablesForIds +
            ')',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [...ids]);
  }

  @override
  Future<void> updateNote(
    int id,
    String note,
    int noteVersion,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Verse set note=?2,noteVersion=?3 WHERE id=?1',
        arguments: [id, note, noteVersion]);
  }

  @override
  Future<void> updateContent(
    int id,
    String content,
    int contentVersion,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Verse set content=?2,contentVersion=?3 WHERE id=?1',
        arguments: [id, content, contentVersion]);
  }

  @override
  Future<void> insertOrFail(List<Verse> entities) async {
    await _verseInsertionAdapter.insertList(entities, OnConflictStrategy.fail);
  }

  @override
  Future<void> updateOrFail(List<Verse> entities) async {
    await _verseUpdateAdapter.updateList(entities, OnConflictStrategy.fail);
  }

  @override
  Future<bool> delete(int verseId) async {
    if (database is sqflite.Transaction) {
      return super.delete(verseId);
    } else {
      return (database as sqflite.Database)
          .transaction<bool>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.verseDao.delete(verseId);
      });
    }
  }

  @override
  Future<int> addFirstVerse(
    int bookId,
    int chapterId,
    int chapterIndex,
  ) async {
    if (database is sqflite.Transaction) {
      return super.addFirstVerse(bookId, chapterId, chapterIndex);
    } else {
      return (database as sqflite.Database)
          .transaction<int>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.verseDao
            .addFirstVerse(bookId, chapterId, chapterIndex);
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
        return transactionDatabase.verseDao.addVerse(raw, verseIndex);
      });
    }
  }

  @override
  Future<bool> updateVerseContent(
    int id,
    String content,
  ) async {
    if (database is sqflite.Transaction) {
      return super.updateVerseContent(id, content);
    } else {
      return (database as sqflite.Database)
          .transaction<bool>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        prepareDb(transactionDatabase);
        return transactionDatabase.verseDao.updateVerseContent(id, content);
      });
    }
  }
}

class _$StatsDao extends StatsDao {
  _$StatsDao(
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
  Future<List<VerseStats>> getStatsByDate(
    int classroomId,
    Date date,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM VerseStats WHERE classroomId = ?1 AND createDate = ?2',
        mapper: (Map<String, Object?> row) => VerseStats(
            verseId: row['verseId'] as int,
            type: row['type'] as int,
            createDate: _dateConverter.decode(row['createDate'] as int),
            createTime: row['createTime'] as int,
            classroomId: row['classroomId'] as int,
            bookId: row['bookId'] as int,
            chapterId: row['chapterId'] as int),
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
        mapper: (Map<String, Object?> row) => VerseStats(verseId: row['verseId'] as int, type: row['type'] as int, createDate: _dateConverter.decode(row['createDate'] as int), createTime: row['createTime'] as int, classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterId: row['chapterId'] as int),
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
        'SELECT DISTINCT verseId FROM VerseStats WHERE classroomId = ?1 AND createDate = ?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classroomId, _dateConverter.encode(date)]);
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
  Future<void> insertKv(CrKv kv) async {
    await _crKvInsertionAdapter.insert(kv, OnConflictStrategy.replace);
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

  @override
  Future<void> deleteByBookId(int bookId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM VerseReview WHERE bookId=?1',
        arguments: [bookId]);
  }

  @override
  Future<void> deleteByChapterId(int chapterId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseReview WHERE chapterId=?1',
        arguments: [chapterId]);
  }

  @override
  Future<void> deleteByVerseId(int verseId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseReview WHERE verseId=?1',
        arguments: [verseId]);
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

  @override
  Future<void> deleteByBookId(int bookId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM VerseStats WHERE bookId=?1',
        arguments: [bookId]);
  }

  @override
  Future<void> deleteByChapterId(int chapterId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseStats WHERE chapterId=?1',
        arguments: [chapterId]);
  }

  @override
  Future<void> deleteByVerseId(int verseId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM VerseStats WHERE verseId=?1',
        arguments: [verseId]);
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
                  'chapterId': item.chapterId,
                  'verseId': item.verseId,
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
    int verseId,
    int type,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM VerseTodayPrg where classroomId=?1 and verseId=?2 and type=?3',
        mapper: (Map<String, Object?> row) => VerseTodayPrg(classroomId: row['classroomId'] as int, bookId: row['bookId'] as int, chapterId: row['chapterId'] as int, verseId: row['verseId'] as int, time: row['time'] as int, type: row['type'] as int, sort: row['sort'] as int, progress: row['progress'] as int, viewTime: _dateTimeConverter.decode(row['viewTime'] as int), reviewCount: row['reviewCount'] as int, reviewCreateDate: _dateConverter.decode(row['reviewCreateDate'] as int), finish: (row['finish'] as int) != 0, id: row['id'] as int?),
        arguments: [classroomId, verseId, type]);
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
  Future<void> deleteByBookId(int bookId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseTodayPrg WHERE bookId=?1',
        arguments: [bookId]);
  }

  @override
  Future<void> deleteByChapterId(int chapterId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseTodayPrg WHERE chapterId=?1',
        arguments: [chapterId]);
  }

  @override
  Future<void> deleteByVerseId(int verseId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM VerseTodayPrg WHERE verseId=?1',
        arguments: [verseId]);
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
final _versionReasonConverter = VersionReasonConverter();
