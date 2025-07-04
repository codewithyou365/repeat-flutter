// dao/chapter_dao.dart

import 'dart:convert' as convert;

import 'package:floor/floor.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/chapter.dart';
import 'package:repeat_flutter/db/entity/chapter_content_version.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content_version.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

@dao
abstract class ChapterDao {
  late AppDatabase db;
  static ChapterShow? Function(int chapterId)? getChapterShow;
  static List<void Function(int chapterId)> setChapterShowContent = [];

  @Query('SELECT Chapter.id chapterId'
      ',Book.id bookId'
      ',Book.name bookName'
      ',Book.sort bookSort'
      ',Chapter.content chapterContent'
      ',Chapter.contentVersion chapterContentVersion'
      ',Chapter.chapterIndex'
      ' FROM Chapter'
      " JOIN Book ON Book.id=Chapter.bookId AND Book.docId!=0"
      ' WHERE Chapter.classroomId=:classroomId'
      ' ORDER BY Chapter.bookId,Chapter.chapterIndex')
  Future<List<ChapterShow>> getAllChapter(int classroomId);

  @Query('SELECT * FROM Chapter WHERE bookId=:bookId')
  Future<List<Chapter>> find(int bookId);

  @Query('SELECT * FROM Chapter WHERE bookId=:bookId and chapterIndex=:chapterIndex')
  Future<Chapter?> one(int bookId, int chapterIndex);

  @Query('SELECT * FROM Chapter WHERE id=:chapterId')
  Future<Chapter?> getById(int chapterId);

  @Query('SELECT count(1) FROM Chapter'
      ' WHERE bookId=:bookId')
  Future<int?> count(int bookId);

  @Query('SELECT * FROM Chapter'
      ' WHERE bookId=:bookId AND chapterIndex>=:minChapterIndex ORDER BY chapterIndex')
  Future<List<Chapter>> findByMinChapterIndex(int bookId, int minChapterIndex);

  @Query('DELETE FROM Chapter'
      ' WHERE bookId=:bookId AND chapterIndex>=:minChapterIndex')
  Future<void> deleteByMinChapterIndex(int bookId, int minChapterIndex);

  @Query('UPDATE Chapter set content=:content,contentVersion=:contentVersion WHERE id=:id')
  Future<void> updateKeyAndContent(int id, String content, int contentVersion);

  @Query('DELETE FROM Chapter'
      ' WHERE Chapter.bookId=:bookId')
  Future<void> deleteByBookId(int bookId);

  @Query('DELETE FROM Chapter'
      ' WHERE Chapter.classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(List<Chapter> entities);

  @Update(onConflict: OnConflictStrategy.fail)
  Future<void> updateOrFail(List<Chapter> entities);

  Future<void> deleteByChapter(Chapter chapter) async {
    var bookId = chapter.bookId;
    var chapterIndex = chapter.chapterIndex;
    return deleteByChapterIndexes(bookId, [chapterIndex]);
  }

  Future<void> deleteByChapterIndexes(int bookId, List<int> chapterIndexes) async {
    chapterIndexes = chapterIndexes.toSet().toList()..sort();

    int minIndex = chapterIndexes.first;
    List<Chapter> entities = await findByMinChapterIndex(bookId, minIndex);

    List<Chapter> needToInserts = [];

    for (var entity in entities) {
      if (chapterIndexes.contains(entity.chapterIndex)) {
        continue;
      }

      int shift = chapterIndexes.where((idx) => idx < entity.chapterIndex).length;
      entity.chapterIndex -= shift;
      needToInserts.add(entity);
    }

    await deleteByMinChapterIndex(bookId, minIndex);
    await insertOrFail(needToInserts);
  }

  Future<void> addChapters(int bookId, List<Chapter> newEntities) async {
    if (newEntities.isEmpty) return;

    newEntities = newEntities.where((c) => c.bookId == bookId).toList();
    newEntities.sort((a, b) => a.chapterIndex.compareTo(b.chapterIndex));

    List<int> newIndexes = newEntities.map((c) => c.chapterIndex).toList();

    int minIndex = newIndexes.reduce((a, b) => a < b ? a : b);
    List<Chapter> oldEntities = await findByMinChapterIndex(bookId, minIndex);

    List<Chapter> needToInserts = [];

    for (var entity in oldEntities) {
      int shift = 0;

      for (var idx in newIndexes) {
        if (entity.chapterIndex >= idx) shift++;
      }

      entity.chapterIndex += shift;
      needToInserts.add(entity);
    }

    await deleteByMinChapterIndex(bookId, minIndex);
    needToInserts.addAll(newEntities);
    await insertOrFail(needToInserts);
  }

  Future<bool> interAddChapter({
    required String chapterContent,
    required int bookId,
    required int chapterIndex,
  }) async {
    var now = DateTime.now();
    int classroomId = Classroom.curr;
    Chapter chapter = Chapter(
      classroomId: classroomId,
      bookId: bookId,
      chapterIndex: chapterIndex,
      content: chapterContent,
      contentVersion: 1,
    );

    Book? book = await db.bookDao.getById(bookId);
    if (book == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["cant find the content data($bookId)"]));
      return false;
    }

    await addChapters(bookId, [chapter]);
    Chapter? newChapter = await one(bookId, chapterIndex);
    if (newChapter == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["cant find the newChapter data($bookId-$chapterIndex)"]));
      return false;
    }

    await db.verseDao.addChapters(bookId, book.sort, [newChapter]);
    await db.chapterContentVersionDao.insertOrFail(ChapterContentVersion(
      classroomId: classroomId,
      bookId: bookId,
      chapterId: newChapter.id!,
      reason: VersionReason.editor,
      version: 1,
      content: chapterContent,
      createTime: now,
    ));
    return true;
  }

  @transaction
  Future<bool> deleteChapter(int chapterId, Rx<Chapter> out) async {
    Chapter? chapter = await db.chapterDao.getById(chapterId);
    if (chapter == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["cant find the chapter data($chapterId)"]));
      return false;
    }
    int bookId = chapter.bookId;
    out.value = chapter;
    var currVerse = await db.verseDao.one(bookId, chapterId, 0);
    if (currVerse != null) {
      Snackbar.showAndThrow(I18nKey.labelChapterDeleteBlocked.tr);
      return false;
    }
    Book? book = await db.bookDao.getById(bookId);
    if (book == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["cant find the content data($bookId)"]));
      return false;
    }
    //await db.bookDao.deleteByClassroomId(classroomId);
    //await db.bookContentVersionDao.deleteByClassroomId(classroomId);
    await deleteByChapter(chapter);
    await db.chapterContentVersionDao.deleteByChapterId(chapterId);
    //await deleteById(classroomId);
    //await db.crKvDao.deleteByClassroomId(classroomId);
    await db.gameDao.deleteByChapterId(chapterId);
    await db.gameUserInputDao.deleteByChapterId(chapterId);
    //await db.timeStatsDao.deleteByClassroomId(classroomId);
    await db.verseDao.deleteByChapter(book, chapter);
    await db.verseContentVersionDao.deleteByChapterId(chapterId);
    await db.verseReviewDao.deleteByChapterId(chapterId);
    await db.verseStatsDao.deleteByChapterId(chapterId);
    await db.verseTodayPrgDao.deleteByChapterId(chapterId);
    return true;
  }

  @transaction
  Future<bool> addChapter(ChapterShow chapterShow, int chapterIndex, Rx<Chapter> out) async {
    int chapterId = chapterShow.chapterId;
    Chapter? baseLk = await getById(chapterId);
    if (baseLk == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["cant find the chapter data($chapterId)"]));
      return false;
    }
    out.value = baseLk;
    return await interAddChapter(
      chapterContent: baseLk.content,
      bookId: baseLk.bookId,
      chapterIndex: chapterIndex,
    );
  }

  @transaction
  Future<bool> addFirstChapter(
    int bookId,
  ) async {
    return await interAddChapter(
      chapterContent: "{}",
      bookId: bookId,
      chapterIndex: 0,
    );
  }

  @transaction
  Future<void> updateChapterContent(int chapterId, String content) async {
    Chapter? chapter = await getById(chapterId);
    if (chapter == null) {
      Snackbar.showAndThrow(I18nKey.labelNotFoundVerse.trArgs([chapterId.toString()]));
      return;
    }

    try {
      Map<String, dynamic> contentM = convert.jsonDecode(content);
      content = convert.jsonEncode(contentM);
    } catch (e) {
      Snackbar.showAndThrow(e.toString());
      return;
    }

    if (chapter.content == content) {
      return;
    }

    var now = DateTime.now();
    await updateKeyAndContent(chapterId, content, chapter.contentVersion + 1);
    await db.chapterContentVersionDao.insertOrIgnore(ChapterContentVersion(
      classroomId: chapter.classroomId,
      bookId: chapter.bookId,
      chapterId: chapterId,
      version: chapter.contentVersion + 1,
      reason: VersionReason.editor,
      content: content,
      createTime: now,
    ));
    if (getChapterShow != null) {
      ChapterShow? chapterShow = getChapterShow!(chapterId);
      if (chapterShow != null) {
        chapterShow.chapterContent = content;
        chapterShow.chapterContentVersion++;
      }
    }
    for (var set in setChapterShowContent) {
      set(chapterId);
    }
  }
}
