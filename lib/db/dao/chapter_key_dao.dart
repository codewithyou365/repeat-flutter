// dao/chapter_key_dao.dart

import 'dart:convert' as convert;

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/content.dart' show Content;
import 'package:repeat_flutter/db/entity/chapter.dart';
import 'package:repeat_flutter/db/entity/chapter_key.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/verse.dart';
import 'package:repeat_flutter/db/entity/verse_key.dart';
import 'package:repeat_flutter/db/entity/text_version.dart';
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
      ' WHERE classroomId=:classroomId and contentSerial=:contentSerial and chapterIndex=:chapterIndex and version=:version')
  Future<int?> getChapterKeyId(int classroomId, int contentSerial, int chapterIndex, int version);

  @Query('SELECT ifnull(sum(Chapter.chapterKeyId is null),0) missingCount'
      ' FROM ChapterKey'
      ' JOIN Content ON Content.id=:contentId AND Content.serial=VerseKey.contentSerial AND Content.docId!=0'
      ' LEFT JOIN Chapter ON Chapter.chapterKeyId=ChapterKey.id')
  Future<int?> getMissingCount(int contentId);

  @Query('SELECT ChapterKey.id chapterKeyId'
      ',Content.id contentId'
      ',Content.name contentName'
      ',Content.sort contentSort'
      ',ChapterKey.content chapterContent'
      ',ChapterKey.contentVersion chapterContentVersion'
      ',ChapterKey.chapterIndex'
      ',Chapter.chapterKeyId is null missing'
      ' FROM ChapterKey'
      " JOIN Content ON Content.classroomId=:classroomId AND Content.serial=ChapterKey.contentSerial AND Content.docId!=0"
      ' LEFT JOIN Chapter ON Chapter.chapterKeyId=ChapterKey.id'
      ' WHERE ChapterKey.classroomId=:classroomId')
  Future<List<ChapterShow>> getAllChapter(int classroomId);

  @Query('SELECT * FROM ChapterKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND chapterIndex>=:minChapterIndex')
  Future<List<ChapterKey>> findByMinChapterIndex(int classroomId, int contentSerial, int minChapterIndex);

  @Query('DELETE FROM ChapterKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND chapterIndex>=:minChapterIndex')
  Future<void> deleteByMinChapterIndex(int classroomId, int contentSerial, int minChapterIndex);

  @Query('UPDATE ChapterKey set content=:content,contentVersion=:contentVersion WHERE id=:id')
  Future<void> updateKeyAndContent(int id, String content, int contentVersion);

  @Query('SELECT * FROM ChapterKey WHERE classroomId=:classroomId and contentSerial=:contentSerial')
  Future<List<ChapterKey>> find(int classroomId, int contentSerial);

  @Query('DELETE FROM ChapterKey WHERE id=:id')
  Future<void> deleteById(int id);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(List<ChapterKey> entities);

  @Update(onConflict: OnConflictStrategy.fail)
  Future<void> updateOrFail(List<ChapterKey> entities);

  Future<bool> import(List<Chapter> newChapters, List<ChapterKey> newChapterKeys, int contentSerial) async {
    List<ChapterKey> oldChapters = await find(Classroom.curr, contentSerial);
    var maxVersion = 0;
    Map<String, ChapterKey> keyToChapter = {};
    Map<String, int> keyToId = {};
    List<int> oldChapterIds = [];
    for (var oldChapter in oldChapters) {
      if (oldChapter.version > maxVersion) {
        maxVersion = oldChapter.version;
      }
      keyToChapter[oldChapter.k] = oldChapter;
      keyToId[oldChapter.k] = oldChapter.id!;
      oldChapterIds.add(oldChapter.id!);
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
      newChapterKeys = await find(Classroom.curr, contentSerial);
      keyToId = {for (var chapterKey in newChapterKeys) chapterKey.k: chapterKey.id!};
    }

    List<TextVersion> oldContentVersion = await db.textVersionDao.getTextForChapter(oldChapterIds);
    Map<int, TextVersion> oldIdToContentVersion = {for (var v in oldContentVersion) v.id: v};
    var needToInsertTextVersion = db.textVersionDao.toNeedToInsert<ChapterKey>(TextVersionType.chapterContent, newChapterKeys, (v) => v.id!, (v) => v.content, oldIdToContentVersion);
    Map<int, TextVersion> newIdToChapterVersion = {for (var v in needToInsertTextVersion) v.id: v};
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

    await db.chapterDao.delete(Classroom.curr, contentSerial);
    if (newChapters.isNotEmpty) {
      await db.chapterDao.insertOrFail(newChapters);
    }
    if (needToModifyMap.isNotEmpty) {
      await updateOrFail(needToModifyMap.values.toList());
    }
    if (needToInsertTextVersion.isNotEmpty) {
      await db.textVersionDao.insertsOrIgnore(needToInsertTextVersion);
    }
    return newChapterKeys.length < keyToId.length;
  }

  @transaction
  Future<void> updateChapterContent(int chapterKeyId, String content) async {
    ChapterKey? chapterKey = await getById(chapterKeyId);
    if (chapterKey == null) {
      Snackbar.show(I18nKey.labelNotFoundVerse.trArgs([chapterKeyId.toString()]));
      return;
    }

    try {
      Map<String, dynamic> contentM = convert.jsonDecode(content);
      content = convert.jsonEncode(contentM);
    } catch (e) {
      Snackbar.show(e.toString());
      return;
    }

    if (chapterKey.content == content) {
      return;
    }

    var now = DateTime.now();
    await updateKeyAndContent(chapterKeyId, content, chapterKey.contentVersion + 1);
    await db.textVersionDao.insertOrIgnore(TextVersion(
      t: TextVersionType.chapterContent,
      id: chapterKeyId,
      version: chapterKey.contentVersion + 1,
      reason: TextVersionReason.editor,
      text: content,
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
    int verseKeyDaoCount = await db.verseKeyDao.count(chapterKey.classroomId, chapterKey.contentSerial, chapterKey.chapterIndex) ?? 0;
    if (verseKeyDaoCount != 0) {
      Snackbar.show(I18nKey.labelChapterHasVersesAndCantBeDeleted.tr);
      return false;
    }
    await db.chapterDao.deleteById(chapterKeyId);
    await deleteById(chapterKeyId);
    return true;
  }

  @transaction
  Future<bool> deleteNormalChapter(int chapterKeyId, Map<String, dynamic> out) async {
    ChapterKey? deleteLk = await getById(chapterKeyId);
    if (deleteLk == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["cant find the chapter data($chapterKeyId)"]));
      return false;
    }
    int classroomId = deleteLk.classroomId;
    int contentSerial = deleteLk.contentSerial;
    int chapterIndex = deleteLk.chapterIndex;
    out['chapterKey'] = deleteLk;
    var currVerse = await db.verseDao.one(classroomId, contentSerial, chapterIndex, 0);
    if (currVerse != null) {
      Snackbar.show(I18nKey.labelChapterDeleteBlocked.tr);
      return false;
    }

    Content? content = await db.contentDao.getBySerial(classroomId, contentSerial);
    if (content == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["cant find the content data($contentSerial)"]));
      return false;
    }

    var chapters = await db.chapterDao.findByMinChapterIndex(classroomId, contentSerial, chapterIndex);
    var chapterKeys = await findByMinChapterIndex(classroomId, contentSerial, chapterIndex);
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
    var verses = await db.verseDao.findByMinChapterIndex(classroomId, contentSerial, chapterIndex);
    var verseKeys = await db.verseKeyDao.findByMinChapterIndex(classroomId, contentSerial, chapterIndex);
    List<Verse> insertVerses = [];
    List<VerseKey> insertVerseKeys = [];
    for (var v in verses) {
      var chapterIndex = v.chapterIndex - 1;
      v.sort = content.sort * 10000000000 + chapterIndex * 100000 + v.verseIndex;
      v.chapterIndex = chapterIndex;
      insertVerses.add(v);
    }
    for (var v in verseKeys) {
      v.chapterIndex--;
      insertVerseKeys.add(v);
    }
    await db.chapterDao.deleteByMinChapterIndex(classroomId, contentSerial, chapterIndex);
    await deleteByMinChapterIndex(classroomId, contentSerial, chapterIndex);
    await db.chapterDao.insertOrFail(insertChapters);
    await insertOrFail(insertChapterKeys);

    await db.verseDao.deleteByMinChapterIndex(classroomId, contentSerial, chapterIndex);
    await db.verseKeyDao.deleteByMinChapterIndex(classroomId, contentSerial, chapterIndex);
    await db.verseDao.insertListOrFail(insertVerses);
    await db.verseKeyDao.insertListOrFail(insertVerseKeys);
    await db.textVersionDao.delete(TextVersionType.chapterContent, deleteLk.id!);
    return true;
  }

  @transaction
  Future<bool> addChapter(ChapterShow chapterShow, int chapterIndex, Map<String, dynamic> out) async {
    int chapterKeyId = chapterShow.chapterKeyId;
    ChapterKey? baseLk = await getById(chapterKeyId);
    if (baseLk == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["cant find the chapter data($chapterKeyId)"]));
      return false;
    }
    out['chapterKey'] = baseLk;
    return await interAddChapter(
      chapterContent: baseLk.content,
      bookSerial: baseLk.contentSerial,
      chapterIndex: chapterIndex,
    );
  }

  @transaction
  Future<bool> addFirstChapter(
    int contentSerial,
  ) async {
    return await interAddChapter(
      chapterContent: "{}",
      bookSerial: contentSerial,
      chapterIndex: 0,
    );
  }

  Future<bool> interAddChapter({
    required String chapterContent,
    required int bookSerial,
    required int chapterIndex,
  }) async {
    var now = DateTime.now();
    int classroomId = Classroom.curr;
    Chapter newChapter = Chapter(
      classroomId: classroomId,
      contentSerial: bookSerial,
      chapterIndex: chapterIndex,
    );
    ChapterKey newChapterKey = ChapterKey(
      classroomId: classroomId,
      contentSerial: bookSerial,
      chapterIndex: chapterIndex,
      version: 1,
      content: chapterContent,
      contentVersion: 1,
    );
    TextVersion newTextVersion = TextVersion(
      t: TextVersionType.chapterContent,
      version: 1,
      reason: TextVersionReason.editor,
      text: chapterContent,
      createTime: now,
    );

    Content? content = await db.contentDao.getBySerial(classroomId, bookSerial);
    if (content == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["cant find the content data($bookSerial)"]));
      return false;
    }
    var chapters = await db.chapterDao.findByMinChapterIndex(classroomId, bookSerial, chapterIndex);
    var chapterKeys = await findByMinChapterIndex(classroomId, bookSerial, chapterIndex);
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
    var verses = await db.verseDao.findByMinChapterIndex(classroomId, bookSerial, chapterIndex);
    var verseKeys = await db.verseKeyDao.findByMinChapterIndex(classroomId, bookSerial, chapterIndex);
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
    await deleteByMinChapterIndex(classroomId, bookSerial, chapterIndex);
    await insertOrFail(insertChapterKeys);
    int? newChapterKeyId = await getChapterKeyId(newChapterKey.classroomId, newChapterKey.contentSerial, newChapterKey.chapterIndex, newChapterKey.version);
    if (newChapterKeyId == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["cant find the newChapterKeyId by ${newChapterKey.classroomId}, ${newChapterKey.contentSerial}, ${newChapterKey.chapterIndex}, ${newChapterKey.version}"]));
      return false;
    }
    newChapter.chapterKeyId = newChapterKeyId;
    newTextVersion.id = newChapterKeyId;

    await db.chapterDao.deleteByMinChapterIndex(classroomId, bookSerial, chapterIndex);
    await db.chapterDao.insertOrFail(insertChapters);

    await db.verseDao.deleteByMinChapterIndex(classroomId, bookSerial, chapterIndex);
    await db.verseKeyDao.deleteByMinChapterIndex(classroomId, bookSerial, chapterIndex);
    await db.verseDao.insertListOrFail(insertVerses);
    await db.verseKeyDao.insertListOrFail(insertVerseKeys);
    await db.textVersionDao.insertOrFail(newTextVersion);

    return true;
  }
}
