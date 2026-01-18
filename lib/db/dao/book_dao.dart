// dao/book_dao.dart

import 'dart:convert' as convert;

import 'package:floor/floor.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/num.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book_content_version.dart';
import 'package:repeat_flutter/db/entity/chapter.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/content_version.dart';
import 'package:repeat_flutter/db/entity/verse.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/cache_help.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

@dao
abstract class BookDao {
  late AppDatabase db;

  @Query(
    'SELECT *'
    ' FROM Book WHERE enable=true ORDER BY classroomId,sort',
  )
  Future<List<Book>> all();

  @Query(
    'SELECT id bookId'
    ',classroomId'
    ',name'
    ',sort'
    ',content bookContent'
    ',contentVersion bookContentVersion'
    ' FROM Book where classroomId=:classroomId and enable=true ORDER BY sort',
  )
  Future<List<BookShow>> getAllBook(int classroomId);

  @Query('SELECT * FROM Book where classroomId=:classroomId ORDER BY sort')
  Future<List<Book>> getAll(int classroomId);

  @Query('SELECT * FROM Book where classroomId=:classroomId and enable=:enable ORDER BY sort')
  Future<List<Book>> getByEnable(int classroomId, bool enable);

  @Query('SELECT ifnull(max(sort),0) FROM Book WHERE classroomId=:classroomId')
  Future<int?> getMaxSort(int classroomId);

  @Query('SELECT ifnull(sort,0) FROM Book WHERE classroomId=:classroomId and sort=:sort')
  Future<int?> existBySort(int classroomId, int sort);

  @Query('SELECT * FROM Book WHERE id=:id')
  Future<Book?> getById(int id);

  @Query('SELECT * FROM Book WHERE classroomId=:classroomId and name=:name')
  Future<Book?> getBookByName(int classroomId, String name);

  @Query('UPDATE Book set content=:content,contentVersion=:contentVersion WHERE Book.id=:id')
  Future<void> updateBookContentVersion(int id, String content, int contentVersion);

  @Query('UPDATE Book set content=:content,contentVersion=:contentVersion,enable=:enable WHERE Book.id=:id')
  Future<void> updateBookContentVersionAndEnable(int id, String content, int contentVersion, bool enable);

  @Query('UPDATE Book set content=:content,contentVersion=:contentVersion,enable=:enable,url=:url WHERE Book.id=:id')
  Future<void> updateBookContentVersionAndStateAndUrl(int id, String content, int contentVersion, bool enable, String url);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertBook(Book entity);

  @Query(
    'UPDATE Book set enable=:enable'
    ' WHERE Book.id=:id',
  )
  Future<void> updateEnable(int id, bool enable);

  @Query(
    'DELETE FROM Book'
    ' WHERE Book.classroomId=:classroomId',
  )
  Future<void> deleteByClassroomId(int classroomId);

  @Query(
    'DELETE FROM Book'
    ' WHERE Book.id=:bookId',
  )
  Future<void> deleteById(int bookId);

  Future<void> updateBookContent(int bookId, String content) async {
    var book = await innerUpdateBookContent(bookId, content);
    if (book.id != null) {
      CacheHelp.updateBookContent(book);
      EventBus().publish<int>(EventTopic.updateBookContent, bookId);
    }
  }

  @transaction
  Future<Book> innerUpdateBookContent(int bookId, String content) async {
    return await _innerUpdateBookContent(bookId: bookId, content: content);
  }

  Future<Book> _innerUpdateBookContent({
    required int bookId,
    required String content,
    bool? enable,
  }) async {
    Book? book = await getById(bookId);
    if (book == null) {
      Snackbar.showAndThrow(I18nKey.labelNotFoundVerse.trArgs([bookId.toString()]));
      return Book.empty();
    }

    try {
      Map<String, dynamic> contentM = convert.jsonDecode(content);
      content = convert.jsonEncode(contentM);
    } catch (e) {
      Snackbar.showAndThrow(e.toString());
      return Book.empty();
    }

    if (book.content == content) {
      return Book.empty();
    }

    var now = DateTime.now();
    if (enable == null) {
      await updateBookContentVersion(bookId, content, book.contentVersion + 1);
    } else {
      await updateBookContentVersionAndEnable(bookId, content, book.contentVersion + 1, enable);
    }

    await db.bookContentVersionDao.insertOrFail(
      BookContentVersion(
        classroomId: book.classroomId,
        bookId: book.id!,
        version: book.contentVersion + 1,
        reason: VersionReason.editor,
        content: content,
        createTime: now,
      ),
    );
    book.content = content;
    book.contentVersion++;
    return book;
  }

  @transaction
  Future<Book> add(String name) async {
    var ret = await getBookByName(Classroom.curr, name);
    if (ret != null) {
      Snackbar.showAndThrow(I18nKey.labelBookNameDuplicated.tr);
    } else {
      var maxSort = await getMaxSort(Classroom.curr);
      var sort = await Num.getNextId(maxSort, id: Classroom.curr, existById2: existBySort);

      var now = DateTime.now().millisecondsSinceEpoch;
      ret = Book(
        classroomId: Classroom.curr,
        name: name,
        desc: '',
        enable: false,
        url: '',
        content: '',
        contentVersion: 0,
        sort: sort,
        createTime: now,
        updateTime: now,
      );
      await insertBook(ret);
    }
    return ret;
  }

  Future<void> create(int bookId, String content) async {
    var book = await innerCreate(bookId, content);
    if (book.id != null) {
      await CacheHelp.refreshBook();
      EventBus().publish<int>(EventTopic.createBook, bookId);
    }
  }

  @transaction
  Future<Book> innerCreate(int bookId, String content) async {
    return await _innerUpdateBookContent(bookId: bookId, content: content, enable: true);
  }

  Future<void> import(Book book, List<Chapter> chapters, List<Verse> verses) async {
    await innerImport(book, chapters, verses);
    await CacheHelp.refreshAll();
    EventBus().publish<int>(EventTopic.importBook, book.id!);
  }

  @transaction
  Future<void> innerImport(Book book, List<Chapter> chapters, List<Verse> verses) async {
    await updateBookContentVersionAndStateAndUrl(book.id!, book.content, 1, true, book.url);
    await db.bookContentVersionDao.import(book);
    chapters = await db.chapterDao.import(chapters);
    await db.chapterContentVersionDao.import(chapters);
    verses = await db.verseDao.import(chapters, verses);
    await db.verseContentVersionDao.import(verses);
  }

  Future<void> reimport(
    Book book,
    List<Chapter> insertChapters,
    List<Chapter> updateChapters,
    List<Verse> insertVerses,
    List<Verse> updateVerses,
    RxInt updateVerseCount,
    RxInt deleteVerseCount,
  ) async {
    await innerReimport(book, insertChapters, updateChapters, insertVerses, updateVerses, updateVerseCount, deleteVerseCount);
    await CacheHelp.refreshAll();
    EventBus().publish<int>(EventTopic.reimportBook, book.id!);
  }

  @transaction
  Future<void> innerReimport(
    Book book,
    List<Chapter> insertChapters,
    List<Chapter> updateChapters,
    List<Verse> insertVerses,
    List<Verse> updateVerses,
    RxInt updateVerseCount,
    RxInt deleteVerseCount,
  ) async {
    var bookId = book.id!;
    BookContentVersion? bookContentVersion = await db.bookContentVersionDao.reimport(book);
    if (bookContentVersion != null) {
      await updateBookContentVersion(bookId, book.content, bookContentVersion.version);
    }
    var deletedChapterIds = await db.chapterDao.reimport(bookId, insertChapters, updateChapters);
    await db.chapterContentVersionDao.reimport(bookId, insertChapters, updateChapters);
    await db.chapterDao.syncContentVersion(bookId);

    await db.gameDao.deleteByChapterIds(deletedChapterIds);
    await db.gameUserInputDao.deleteByChapterIds(deletedChapterIds);
    await db.verseReviewDao.deleteByChapterIds(deletedChapterIds);
    await db.verseStatsDao.deleteByChapterIds(deletedChapterIds);
    await db.verseTodayPrgDao.deleteByChapterIds(deletedChapterIds);

    var deletedVerseIds = await db.verseDao.reimport(bookId, insertChapters, updateChapters, insertVerses, updateVerses);
    deleteVerseCount.value = deletedVerseIds.length;
    await db.verseContentVersionDao.reimport(bookId, insertVerses, updateVerses, updateVerseCount);
    await db.verseDao.syncContentVersion(bookId);

    await db.gameDao.deleteByVerseIds(deletedVerseIds);
    await db.gameUserInputDao.deleteByVerseIds(deletedVerseIds);
    await db.verseReviewDao.deleteByVerseIds(deletedVerseIds);
    await db.verseStatsDao.deleteByVerseIds(deletedVerseIds);
    await db.verseTodayPrgDao.deleteByVerseIds(deletedVerseIds);
  }

  Future<void> deleteBook(int bookId) async {
    await innerDeleteBook(bookId);
    await CacheHelp.refreshAll();
    EventBus().publish<int>(EventTopic.deleteBook, bookId);
  }

  @transaction
  Future<void> innerDeleteBook(int bookId) async {
    await deleteById(bookId);
    await db.bookContentVersionDao.deleteByBookId(bookId);
    await db.chapterDao.deleteByBookId(bookId);
    await db.chapterContentVersionDao.deleteByBookId(bookId);
    //await db.classroomDao.deleteById(classroomId);
    //await db.crKvDao.deleteByClassroomId(classroomId);
    await db.gameDao.deleteByBookId(bookId);
    await db.gameUserInputDao.deleteByBookId(bookId);
    //await db.timeStatsDao.deleteByClassroomId(classroomId);
    await db.verseDao.deleteByBookId(bookId);
    await db.verseContentVersionDao.deleteByBookId(bookId);
    await db.verseReviewDao.deleteByBookId(bookId);
    await db.verseStatsDao.deleteByBookId(bookId);
    await db.verseTodayPrgDao.deleteByBookId(bookId);
  }
}
