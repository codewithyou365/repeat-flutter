// dao/book_dao.dart

import 'dart:convert' as convert;

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/num.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book_content_version.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/content_version.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

@dao
abstract class BookDao {
  late AppDatabase db;
  static BookShow? Function(int chapterId)? getBookShow;
  static List<void Function(int chapterId)> setBookShowContent = [];

  @Query('SELECT id bookId'
      ',classroomId'
      ',name'
      ',sort'
      ',content bookContent'
      ',contentVersion bookContentVersion'
      ' FROM Book where classroomId=:classroomId and hide=false and docId!=0 ORDER BY sort')
  Future<List<BookShow>> getAllBook(int classroomId);

  @Query('SELECT * FROM Book where classroomId=:classroomId and hide=false ORDER BY sort')
  Future<List<Book>> getAll(int classroomId);

  @Query('SELECT max(verseWarning) FROM Book where classroomId=:classroomId and docId!=0 and hide=false')
  Future<bool?> hasWarning(int classroomId);

  @Query('SELECT * FROM Book where classroomId=:classroomId and docId!=0 and hide=false ORDER BY sort')
  Future<List<Book>> getAllEnableBook(int classroomId);

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

  @Query('UPDATE Book set docId=:docId,url=:url,chapterWarning=:chapterWarning,verseWarning=:verseWarning,updateTime=:updateTime WHERE Book.id=:id')
  Future<void> updateBook(int id, int docId, String url, bool chapterWarning, bool verseWarning, int updateTime);

  @Query('UPDATE Book set chapterWarning=:chapterWarning,verseWarning=:verseWarning,updateTime=:updateTime WHERE Book.id=:id')
  Future<void> updateBookWarning(int id, bool chapterWarning, bool verseWarning, int updateTime);

  @Query('UPDATE Book set chapterWarning=:chapterWarning,updateTime=:updateTime WHERE Book.id=:id')
  Future<void> updateBookWarningForChapter(int id, bool chapterWarning, int updateTime);

  @Query('UPDATE Book set verseWarning=:verseWarning,updateTime=:updateTime WHERE Book.id=:id')
  Future<void> updateBookWarningForVerse(int id, bool verseWarning, int updateTime);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertBook(Book entity);

  @Query('UPDATE Book set hide=true'
      ' WHERE Book.id=:id')
  Future<void> hide(int id);

  @Query('UPDATE Book set hide=false'
      ' WHERE Book.id=:id')
  Future<void> show(int id);

  @Query('UPDATE Book set docId=:docId'
      ' WHERE Book.id=:id')
  Future<void> updateDocId(int id, int docId);

  @Query('DELETE FROM Book'
      ' WHERE Book.classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @transaction
  Future<void> updateBookContent(int bookId, String content) async {
    await innerUpdateBookContent(bookId, content);
  }

  Future<void> innerUpdateBookContent(int bookId, String content) async {
    Book? book = await getById(bookId);
    if (book == null) {
      Snackbar.showAndThrow(I18nKey.labelNotFoundVerse.trArgs([bookId.toString()]));
      return;
    }

    try {
      Map<String, dynamic> contentM = convert.jsonDecode(content);
      content = convert.jsonEncode(contentM);
    } catch (e) {
      Snackbar.showAndThrow(e.toString());
      return;
    }

    if (book.content == content) {
      return;
    }

    var now = DateTime.now();
    await updateBookContentVersion(bookId, content, book.contentVersion + 1);
    await db.bookContentVersionDao.insertOrIgnore(BookContentVersion(
      classroomId: book.classroomId,
      bookId: book.id!,
      version: book.contentVersion + 1,
      reason: VersionReason.editor,
      content: content,
      createTime: now,
    ));
    if (getBookShow != null) {
      BookShow? bookShow = getBookShow!(bookId);
      if (bookShow != null) {
        bookShow.bookContent = content;
        for (var set in setBookShowContent) {
          set(bookId);
        }
        bookShow.bookContentVersion++;
      }
    }
  }

  @transaction
  Future<Book> add(String name) async {
    var ret = await getBookByName(Classroom.curr, name);
    if (ret != null) {
      if (ret.hide == false) {
        Snackbar.show(I18nKey.labelDataDuplication.tr);
        return ret;
      }
      await show(ret.id!);
    } else {
      var maxSort = await getMaxSort(Classroom.curr);
      var sort = await Num.getNextId(maxSort, id: Classroom.curr, existById2: existBySort);

      var now = DateTime.now().millisecondsSinceEpoch;
      ret = Book(
        classroomId: Classroom.curr,
        name: name,
        desc: '',
        docId: 0,
        url: '',
        content: '',
        contentVersion: 0,
        sort: sort,
        hide: false,
        chapterWarning: false,
        verseWarning: false,
        createTime: now,
        updateTime: now,
      );
      await insertBook(ret);
    }
    return ret;
  }

  @transaction
  Future<void> create(int bookId, String content) async {
    await innerUpdateBookContent(bookId, content);
    await updateDocId(bookId, 1);
  }

  Future<void> import(int bookId, String content) async {
    Book? oldBook = await getById(bookId);
    if (oldBook == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.tr);
      return;
    }
    BookContentVersion? oldBookContentVersion = await db.bookContentVersionDao.one(bookId, oldBook.contentVersion);

    if (oldBookContentVersion == null || oldBookContentVersion.content != content) {
      var maxVersion = oldBook.contentVersion;
      var nextVersion = maxVersion + 1;
      BookContentVersion insertBookContentVersion = BookContentVersion(
        classroomId: oldBook.classroomId,
        bookId: oldBook.id!,
        version: nextVersion,
        reason: VersionReason.import,
        content: content,
        createTime: DateTime.now(),
      );
      await db.bookContentVersionDao.insertOrIgnore(insertBookContentVersion);
      await updateBookContentVersion(oldBook.id!, content, nextVersion);
    }
  }
}
