// dao/chapter_key_dao.dart

import 'dart:convert' as convert;

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book.dart' show Book;
import 'package:repeat_flutter/db/entity/chapter.dart';
import 'package:repeat_flutter/db/entity/chapter_content_version.dart';
import 'package:repeat_flutter/db/entity/chapter_key.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/verse.dart';
import 'package:repeat_flutter/db/entity/verse_key.dart';
import 'package:repeat_flutter/db/entity/content_version.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

@dao
abstract class ChapterKeyDao {
  late AppDatabase db;
  static ChapterShow? Function(int chapterKeyId)? getChapterShow;
  static List<void Function(int chapterKeyId)> setChapterShowContent = [];

  @Query('SELECT *'
      ' FROM ChapterKey'
      ' WHERE ChapterKey.id=:id')
  Future<ChapterKey?> getById(int id);

  @Query('SELECT id'
      ' FROM ChapterKey'
      ' WHERE bookId=:bookId and chapterIndex=:chapterIndex and version=:version')
  Future<int?> getChapterKeyId(int bookId, int chapterIndex, int version);

  @Query('SELECT ifnull(sum(Chapter.chapterKeyId is null),0) missingCount'
      ' FROM ChapterKey'
      ' JOIN Book ON Book.id=:bookId AND Book.docId!=0'
      ' LEFT JOIN Chapter ON Chapter.chapterKeyId=ChapterKey.id')
  Future<int?> getMissingCount(int bookId);

  @Query('SELECT ChapterKey.id chapterKeyId'
      ',Book.id bookId'
      ',Book.name bookName'
      ',Book.sort bookSort'
      ',ChapterKey.content chapterContent'
      ',ChapterKey.contentVersion chapterContentVersion'
      ',ChapterKey.chapterIndex'
      ',Chapter.chapterKeyId is null missing'
      ' FROM ChapterKey'
      " JOIN Book ON Book.id=ChapterKey.bookId AND Book.docId!=0"
      ' LEFT JOIN Chapter ON Chapter.chapterKeyId=ChapterKey.id'
      ' WHERE ChapterKey.classroomId=:classroomId')
  Future<List<ChapterShow>> getAllChapter(int classroomId);

  @Query('SELECT * FROM ChapterKey'
      ' WHERE bookId=:bookId AND chapterIndex>=:minChapterIndex')
  Future<List<ChapterKey>> findByMinChapterIndex(int bookId, int minChapterIndex);

  @Query('DELETE FROM ChapterKey'
      ' WHERE bookId=:bookId AND chapterIndex>=:minChapterIndex')
  Future<void> deleteByMinChapterIndex(int bookId, int minChapterIndex);

  @Query('DELETE FROM ChapterKey'
      ' WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('UPDATE ChapterKey set content=:content,contentVersion=:contentVersion WHERE id=:id')
  Future<void> updateKeyAndContent(int id, String content, int contentVersion);

  @Query('SELECT * FROM ChapterKey WHERE bookId=:bookId')
  Future<List<ChapterKey>> findByBook(int bookId);

  @Query('SELECT * FROM ChapterKey WHERE bookId=:bookId and version=:version')
  Future<List<ChapterKey>> findByBookAndVersion(int bookId, int version);

  @Query('DELETE FROM ChapterKey WHERE id=:id')
  Future<void> deleteById(int id);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(List<ChapterKey> entities);

  @Update(onConflict: OnConflictStrategy.fail)
  Future<void> updateOrFail(List<ChapterKey> entities);

  Future<bool> import(List<Chapter> newChapters, List<ChapterKey> newChapterKeys, int bookId) async {
    List<ChapterKey> oldChapters = await findByBook(bookId);
    var maxVersion = 0;
    Map<String, ChapterKey> keyToChapter = {};
    Map<String, int> keyToId = {};
    for (var oldChapter in oldChapters) {
      if (oldChapter.version > maxVersion) {
        maxVersion = oldChapter.version;
      }
      keyToChapter[oldChapter.k] = oldChapter;
      keyToId[oldChapter.k] = oldChapter.id!;
    }
    var nextVersion = maxVersion + 1;
    Map<int, ChapterKey> needToModifyMap = {};
    List<ChapterKey> needToInsert = [];
    for (var newChapter in newChapterKeys) {
      newChapter.version = nextVersion;
      ChapterKey? oldChapter = keyToChapter[newChapter.k];
      if (oldChapter == null) {
        needToInsert.add(newChapter);
      } else {
        newChapter.id = oldChapter.id;
        newChapter.contentVersion = oldChapter.contentVersion;
        if (oldChapter.chapterIndex != newChapter.chapterIndex || //
            oldChapter.content != newChapter.content) {
          needToModifyMap[oldChapter.id!] = newChapter;
        }
      }
    }
    if (needToInsert.isNotEmpty) {
      await insertOrFail(needToInsert);
      newChapterKeys.clear();
      newChapterKeys.addAll(await findByBookAndVersion(bookId, nextVersion));
      newChapterKeys.addAll(needToModifyMap.values);
      newChapterKeys.sort((a, b) => a.chapterIndex.compareTo(b.chapterIndex));
      keyToId = {for (var chapterKey in newChapterKeys) chapterKey.k: chapterKey.id!};
    }

    List<ChapterContentVersion> needToInsertChapterContentVersion = await db.chapterContentVersionDao.import(newChapterKeys, bookId);
    Map<int, ChapterContentVersion> newIdToChapterVersion = {for (var v in needToInsertChapterContentVersion) v.chapterKeyId: v};
    for (var i = 0; i < newChapterKeys.length; i++) {
      ChapterKey newChapter = newChapterKeys[i];
      var id = keyToId[newChapter.k]!;
      var contentVersion = newIdToChapterVersion[id];
      if (contentVersion != null && newChapter.contentVersion != contentVersion.version) {
        newChapter.contentVersion = contentVersion.version;
        needToModifyMap[newChapter.id!] = newChapter;
      }
      newChapters[i].chapterKeyId = id;
    }

    await db.chapterDao.delete(bookId);
    if (newChapters.isNotEmpty) {
      await db.chapterDao.insertOrFail(newChapters);
    }
    if (needToModifyMap.isNotEmpty) {
      await updateOrFail(needToModifyMap.values.toList());
    }
    return newChapterKeys.length < keyToId.length;
  }

  @transaction
  Future<void> updateChapterContent(int chapterKeyId, String content) async {
    ChapterKey? chapterKey = await getById(chapterKeyId);
    if (chapterKey == null) {
      Snackbar.showAndThrow(I18nKey.labelNotFoundVerse.trArgs([chapterKeyId.toString()]));
      return;
    }

    try {
      Map<String, dynamic> contentM = convert.jsonDecode(content);
      content = convert.jsonEncode(contentM);
    } catch (e) {
      Snackbar.showAndThrow(e.toString());
      return;
    }

    if (chapterKey.content == content) {
      return;
    }

    var now = DateTime.now();
    await updateKeyAndContent(chapterKeyId, content, chapterKey.contentVersion + 1);
    await db.chapterContentVersionDao.insertOrIgnore(ChapterContentVersion(
      classroomId: chapterKey.classroomId,
      bookId: chapterKey.bookId,
      chapterKeyId: chapterKeyId,
      version: chapterKey.contentVersion + 1,
      reason: VersionReason.editor,
      content: content,
      createTime: now,
    ));
    if (getChapterShow != null) {
      ChapterShow? chapterShow = getChapterShow!(chapterKeyId);
      if (chapterShow != null) {
        chapterShow.chapterContent = content;
        for (var set in setChapterShowContent) {
          set(chapterKeyId);
        }
        chapterShow.chapterContentVersion++;
      }
    }
  }

  @transaction
  Future<bool> deleteAbnormalChapter(int chapterKeyId) async {
    ChapterKey? chapterKey = await getById(chapterKeyId);
    if (chapterKey == null) {
      return true;
    }
    int verseKeyDaoCount = await db.verseKeyDao.count(chapterKey.id!) ?? 0;
    if (verseKeyDaoCount != 0) {
      Snackbar.showAndThrow(I18nKey.labelChapterHasVersesAndCantBeDeleted.tr);
      return false;
    }
    //await db.bookDao.deleteByClassroomId(classroomId);
    //await db.bookContentVersionDao.deleteByClassroomId(classroomId);
    await db.chapterDao.deleteByChapterKeyId(chapterKeyId);
    await db.chapterContentVersionDao.deleteByChapterKeyId(chapterKeyId);
    await deleteById(chapterKeyId);
    //await db.crKvDao.deleteByChapterKeyId(chapterKeyId);
    await db.gameDao.deleteByChapterKeyId(chapterKeyId);
    await db.gameUserInputDao.deleteByChapterKeyId(chapterKeyId);
    //await db.timeStatsDao.deleteByChapterKeyId(chapterKeyId);
    await db.verseDao.deleteByChapterKeyId(chapterKeyId);
    await db.verseContentVersionDao.deleteByChapterKeyId(chapterKeyId);
    await db.verseKeyDao.deleteByChapterKeyId(chapterKeyId);
    await db.verseOverallPrgDao.deleteByChapterKeyId(chapterKeyId);
    await db.verseReviewDao.deleteByChapterKeyId(chapterKeyId);
    await db.verseStatsDao.deleteByChapterKeyId(chapterKeyId);
    await db.verseTodayPrgDao.deleteByChapterKeyId(chapterKeyId);

    return true;
  }

  @transaction
  Future<bool> deleteNormalChapter(int chapterKeyId, Map<String, dynamic> out) async {
    ChapterKey? deleteChapterKey = await getById(chapterKeyId);
    if (deleteChapterKey == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["cant find the chapter data($chapterKeyId)"]));
      return false;
    }
    int bookId = deleteChapterKey.bookId;
    int chapterIndex = deleteChapterKey.chapterIndex;
    out['chapterKey'] = deleteChapterKey;
    var currVerse = await db.verseDao.one(bookId, chapterIndex, 0);
    if (currVerse != null) {
      Snackbar.showAndThrow(I18nKey.labelChapterDeleteBlocked.tr);
      return false;
    }

    Book? book = await db.bookDao.getById(bookId);
    if (book == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["cant find the content data($bookId)"]));
      return false;
    }

    var chapters = await db.chapterDao.findByMinChapterIndex(bookId, chapterIndex);
    var chapterKeys = await findByMinChapterIndex(bookId, chapterIndex);
    List<Chapter> insertChapters = [];
    List<ChapterKey> insertChapterKeys = [];
    for (var v in chapters) {
      if (v.chapterIndex == chapterIndex) {
        continue;
      }
      v.chapterIndex--;
      insertChapters.add(v);
    }
    for (var v in chapterKeys) {
      if (v.chapterIndex == chapterIndex) {
        continue;
      }
      v.chapterIndex--;
      insertChapterKeys.add(v);
    }
    var verses = await db.verseDao.findByMinChapterIndex(bookId, chapterIndex);
    var verseKeys = await db.verseKeyDao.findByMinChapterIndex(bookId, chapterIndex);
    List<Verse> insertVerses = [];
    List<VerseKey> insertVerseKeys = [];
    for (var v in verses) {
      var chapterIndex = v.chapterIndex - 1;
      v.sort = book.sort * 10000000000 + chapterIndex * 100000 + v.verseIndex;
      v.chapterIndex = chapterIndex;
      insertVerses.add(v);
    }
    for (var v in verseKeys) {
      v.chapterIndex--;
      insertVerseKeys.add(v);
    }
    await db.chapterDao.deleteByMinChapterIndex(bookId, chapterIndex);
    await deleteByMinChapterIndex(bookId, chapterIndex);
    await db.chapterDao.insertOrFail(insertChapters);
    await insertOrFail(insertChapterKeys);

    await db.verseDao.deleteByMinChapterIndex(bookId, chapterIndex);
    await db.verseKeyDao.deleteByMinChapterIndex(bookId, chapterIndex);
    await db.verseDao.insertListOrFail(insertVerses);
    await db.verseKeyDao.insertListOrFail(insertVerseKeys);
    await db.chapterContentVersionDao.deleteByChapterKeyId(deleteChapterKey.id!);
    return true;
  }

  @transaction
  Future<bool> addChapter(ChapterShow chapterShow, int chapterIndex, Map<String, dynamic> out) async {
    int chapterKeyId = chapterShow.chapterKeyId;
    ChapterKey? baseLk = await getById(chapterKeyId);
    if (baseLk == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["cant find the chapter data($chapterKeyId)"]));
      return false;
    }
    out['chapterKey'] = baseLk;
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

  Future<bool> interAddChapter({
    required String chapterContent,
    required int bookId,
    required int chapterIndex,
  }) async {
    var now = DateTime.now();
    int classroomId = Classroom.curr;
    Chapter newChapter = Chapter(
      classroomId: classroomId,
      bookId: bookId,
      chapterIndex: chapterIndex,
    );
    ChapterKey newChapterKey = ChapterKey(
      classroomId: classroomId,
      bookId: bookId,
      chapterIndex: chapterIndex,
      version: 1,
      content: chapterContent,
      contentVersion: 1,
    );
    ChapterContentVersion newTextVersion = ChapterContentVersion(
      classroomId: classroomId,
      bookId: bookId,
      chapterKeyId: 0,
      reason: VersionReason.editor,
      version: 1,
      content: chapterContent,
      createTime: now,
    );

    Book? content = await db.bookDao.getById(bookId);
    if (content == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["cant find the content data($bookId)"]));
      return false;
    }
    var chapters = await db.chapterDao.findByMinChapterIndex(bookId, chapterIndex);
    var chapterKeys = await findByMinChapterIndex(bookId, chapterIndex);
    List<Chapter> insertChapters = [newChapter];
    List<ChapterKey> insertChapterKeys = [newChapterKey];
    for (var v in chapters) {
      v.chapterIndex++;
      insertChapters.add(v);
    }
    for (var v in chapterKeys) {
      v.chapterIndex++;
      insertChapterKeys.add(v);
    }
    var verses = await db.verseDao.findByMinChapterIndex(bookId, chapterIndex);
    var verseKeys = await db.verseKeyDao.findByMinChapterIndex(bookId, chapterIndex);
    List<Verse> insertVerses = [];
    List<VerseKey> insertVerseKeys = [];
    for (var v in verses) {
      var chapterIndex = v.chapterIndex + 1;
      v.sort = content.sort * 10000000000 + chapterIndex * 100000 + v.verseIndex;
      v.chapterIndex = chapterIndex;
      insertVerses.add(v);
    }
    for (var v in verseKeys) {
      v.chapterIndex++;
      insertVerseKeys.add(v);
    }
    await deleteByMinChapterIndex(bookId, chapterIndex);
    await insertOrFail(insertChapterKeys);
    int? newChapterKeyId = await getChapterKeyId(newChapterKey.bookId, newChapterKey.chapterIndex, newChapterKey.version);
    if (newChapterKeyId == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["cant find the newChapterKeyId by ${newChapterKey.bookId}, ${newChapterKey.chapterIndex}, ${newChapterKey.version}"]));
      return false;
    }
    newChapter.chapterKeyId = newChapterKeyId;
    newTextVersion.chapterKeyId = newChapterKeyId;

    await db.chapterDao.deleteByMinChapterIndex(bookId, chapterIndex);
    await db.chapterDao.insertOrFail(insertChapters);

    await db.verseDao.deleteByMinChapterIndex(bookId, chapterIndex);
    await db.verseKeyDao.deleteByMinChapterIndex(bookId, chapterIndex);
    await db.verseDao.insertListOrFail(insertVerses);
    await db.verseKeyDao.insertListOrFail(insertVerseKeys);
    await db.chapterContentVersionDao.insertOrFail(newTextVersion);

    return true;
  }
}
