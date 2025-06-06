// dao/lesson_key_dao.dart

import 'dart:convert' as convert;

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/content.dart' show Content;
import 'package:repeat_flutter/db/entity/lesson.dart';
import 'package:repeat_flutter/db/entity/lesson_key.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/verse.dart';
import 'package:repeat_flutter/db/entity/verse_key.dart';
import 'package:repeat_flutter/db/entity/text_version.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/lesson_show.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

@dao
abstract class LessonKeyDao {
  late AppDatabase db;
  static LessonShow? Function(int lessonKeyId)? getLessonShow;
  static List<void Function(int lessonKeyId)> setLessonShowContent = [];

  @Query('SELECT *'
      ' FROM LessonKey'
      ' WHERE LessonKey.id=:id')
  Future<LessonKey?> getById(int id);

  @Query('SELECT id'
      ' FROM LessonKey'
      ' WHERE classroomId=:classroomId and contentSerial=:contentSerial and lessonIndex=:lessonIndex and version=:version')
  Future<int?> getLessonKeyId(int classroomId, int contentSerial, int lessonIndex, int version);

  @Query('SELECT ifnull(sum(Lesson.lessonKeyId is null),0) missingCount'
      ' FROM LessonKey'
      ' JOIN Content ON Content.id=:contentId AND Content.serial=VerseKey.contentSerial AND Content.docId!=0'
      ' LEFT JOIN Lesson ON Lesson.lessonKeyId=LessonKey.id')
  Future<int?> getMissingCount(int contentId);

  @Query('SELECT LessonKey.id lessonKeyId'
      ',Content.id contentId'
      ',Content.name contentName'
      ',Content.sort contentSort'
      ',LessonKey.content lessonContent'
      ',LessonKey.contentVersion lessonContentVersion'
      ',LessonKey.lessonIndex'
      ',Lesson.lessonKeyId is null missing'
      ' FROM LessonKey'
      " JOIN Content ON Content.classroomId=:classroomId AND Content.serial=LessonKey.contentSerial AND Content.docId!=0"
      ' LEFT JOIN Lesson ON Lesson.lessonKeyId=LessonKey.id'
      ' WHERE LessonKey.classroomId=:classroomId')
  Future<List<LessonShow>> getAllLesson(int classroomId);

  @Query('SELECT * FROM LessonKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex>=:minLessonIndex')
  Future<List<LessonKey>> findByMinLessonIndex(int classroomId, int contentSerial, int minLessonIndex);

  @Query('DELETE FROM LessonKey'
      ' WHERE classroomId=:classroomId AND contentSerial=:contentSerial AND lessonIndex>=:minLessonIndex')
  Future<void> deleteByMinLessonIndex(int classroomId, int contentSerial, int minLessonIndex);

  @Query('UPDATE LessonKey set content=:content,contentVersion=:contentVersion WHERE id=:id')
  Future<void> updateKeyAndContent(int id, String content, int contentVersion);

  @Query('SELECT * FROM LessonKey WHERE classroomId=:classroomId and contentSerial=:contentSerial')
  Future<List<LessonKey>> find(int classroomId, int contentSerial);

  @Query('DELETE FROM LessonKey WHERE id=:id')
  Future<void> deleteById(int id);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(List<LessonKey> entities);

  @Update(onConflict: OnConflictStrategy.fail)
  Future<void> updateOrFail(List<LessonKey> entities);

  Future<bool> import(List<Lesson> newLessons, List<LessonKey> newLessonKeys, int contentSerial) async {
    List<LessonKey> oldLessons = await find(Classroom.curr, contentSerial);
    var maxVersion = 0;
    Map<String, LessonKey> keyToLesson = {};
    Map<String, int> keyToId = {};
    List<int> oldLessonIds = [];
    for (var oldLesson in oldLessons) {
      if (oldLesson.version > maxVersion) {
        maxVersion = oldLesson.version;
      }
      keyToLesson[oldLesson.k] = oldLesson;
      keyToId[oldLesson.k] = oldLesson.id!;
      oldLessonIds.add(oldLesson.id!);
    }
    var nextVersion = maxVersion + 1;
    Map<int, LessonKey> needToModifyMap = {};
    List<LessonKey> needToInsert = [];
    for (var newLesson in newLessonKeys) {
      newLesson.version = nextVersion;
      LessonKey? oldLesson = keyToLesson[newLesson.k];
      if (oldLesson == null) {
        needToInsert.add(newLesson);
      } else {
        newLesson.id = oldLesson.id;
        newLesson.contentVersion = oldLesson.contentVersion;
        if (oldLesson.lessonIndex != newLesson.lessonIndex || //
            oldLesson.content != newLesson.content) {
          needToModifyMap[oldLesson.id!] = newLesson;
        }
      }
    }
    if (needToInsert.isNotEmpty) {
      await insertOrFail(needToInsert);
      newLessonKeys = await find(Classroom.curr, contentSerial);
      keyToId = {for (var lessonKey in newLessonKeys) lessonKey.k: lessonKey.id!};
    }

    List<TextVersion> oldContentVersion = await db.textVersionDao.getTextForLesson(oldLessonIds);
    Map<int, TextVersion> oldIdToContentVersion = {for (var v in oldContentVersion) v.id: v};
    var needToInsertTextVersion = db.textVersionDao.toNeedToInsert<LessonKey>(TextVersionType.lessonContent, newLessonKeys, (v) => v.id!, (v) => v.content, oldIdToContentVersion);
    Map<int, TextVersion> newIdToLessonVersion = {for (var v in needToInsertTextVersion) v.id: v};
    for (var i = 0; i < newLessonKeys.length; i++) {
      LessonKey newLesson = newLessonKeys[i];
      var id = keyToId[newLesson.k]!;
      var contentVersion = newIdToLessonVersion[id];
      if (contentVersion != null && newLesson.contentVersion != contentVersion.version) {
        newLesson.contentVersion = contentVersion.version;
        needToModifyMap[newLesson.id!] = newLesson;
      }
      newLessons[i].lessonKeyId = id;
    }

    await db.lessonDao.delete(Classroom.curr, contentSerial);
    if (newLessons.isNotEmpty) {
      await db.lessonDao.insertOrFail(newLessons);
    }
    if (needToModifyMap.isNotEmpty) {
      await updateOrFail(needToModifyMap.values.toList());
    }
    if (needToInsertTextVersion.isNotEmpty) {
      await db.textVersionDao.insertsOrIgnore(needToInsertTextVersion);
    }
    return newLessonKeys.length < keyToId.length;
  }

  @transaction
  Future<void> updateLessonContent(int lessonKeyId, String content) async {
    LessonKey? lessonKey = await getById(lessonKeyId);
    if (lessonKey == null) {
      Snackbar.show(I18nKey.labelNotFoundVerse.trArgs([lessonKeyId.toString()]));
      return;
    }

    try {
      Map<String, dynamic> contentM = convert.jsonDecode(content);
      content = convert.jsonEncode(contentM);
    } catch (e) {
      Snackbar.show(e.toString());
      return;
    }

    if (lessonKey.content == content) {
      return;
    }

    var now = DateTime.now();
    await updateKeyAndContent(lessonKeyId, content, lessonKey.contentVersion + 1);
    await db.textVersionDao.insertOrIgnore(TextVersion(
      t: TextVersionType.lessonContent,
      id: lessonKeyId,
      version: lessonKey.contentVersion + 1,
      reason: TextVersionReason.editor,
      text: content,
      createTime: now,
    ));
    if (getLessonShow != null) {
      LessonShow? lessonShow = getLessonShow!(lessonKeyId);
      if (lessonShow != null) {
        lessonShow.lessonContent = content;
        for (var set in setLessonShowContent) {
          set(lessonKeyId);
        }
        lessonShow.lessonContentVersion++;
      }
    }
  }

  @transaction
  Future<bool> deleteAbnormalLesson(int lessonKeyId) async {
    LessonKey? lessonKey = await getById(lessonKeyId);
    if (lessonKey == null) {
      return true;
    }
    int verseKeyDaoCount = await db.verseKeyDao.count(lessonKey.classroomId, lessonKey.contentSerial, lessonKey.lessonIndex) ?? 0;
    if (verseKeyDaoCount != 0) {
      Snackbar.show(I18nKey.labelLessonHasVersesAndCantBeDeleted.tr);
      return false;
    }
    await db.lessonDao.deleteById(lessonKeyId);
    await deleteById(lessonKeyId);
    return true;
  }

  @transaction
  Future<bool> deleteNormalLesson(int lessonKeyId, Map<String, dynamic> out) async {
    LessonKey? deleteLk = await getById(lessonKeyId);
    if (deleteLk == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["cant find the lesson data($lessonKeyId)"]));
      return false;
    }
    int classroomId = deleteLk.classroomId;
    int contentSerial = deleteLk.contentSerial;
    int lessonIndex = deleteLk.lessonIndex;
    out['lessonKey'] = deleteLk;
    var currVerse = await db.verseDao.one(classroomId, contentSerial, lessonIndex, 0);
    if (currVerse != null) {
      Snackbar.show(I18nKey.labelLessonDeleteBlocked.tr);
      return false;
    }

    Content? content = await db.contentDao.getBySerial(classroomId, contentSerial);
    if (content == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["cant find the content data($contentSerial)"]));
      return false;
    }

    var lessons = await db.lessonDao.findByMinLessonIndex(classroomId, contentSerial, lessonIndex);
    var lessonKeys = await findByMinLessonIndex(classroomId, contentSerial, lessonIndex);
    List<Lesson> insertLessons = [];
    List<LessonKey> insertLessonKeys = [];
    for (var v in lessons) {
      if (v.lessonIndex == lessonIndex) {
        continue;
      }
      v.lessonIndex--;
      insertLessons.add(v);
    }
    for (var v in lessonKeys) {
      if (v.lessonIndex == lessonIndex) {
        continue;
      }
      v.lessonIndex--;
      insertLessonKeys.add(v);
    }
    var verses = await db.verseDao.findByMinLessonIndex(classroomId, contentSerial, lessonIndex);
    var verseKeys = await db.verseKeyDao.findByMinLessonIndex(classroomId, contentSerial, lessonIndex);
    List<Verse> insertVerses = [];
    List<VerseKey> insertVerseKeys = [];
    for (var v in verses) {
      var lessonIndex = v.lessonIndex - 1;
      v.sort = content.sort * 10000000000 + lessonIndex * 100000 + v.verseIndex;
      v.lessonIndex = lessonIndex;
      insertVerses.add(v);
    }
    for (var v in verseKeys) {
      v.lessonIndex--;
      insertVerseKeys.add(v);
    }
    await db.lessonDao.deleteByMinLessonIndex(classroomId, contentSerial, lessonIndex);
    await deleteByMinLessonIndex(classroomId, contentSerial, lessonIndex);
    await db.lessonDao.insertOrFail(insertLessons);
    await insertOrFail(insertLessonKeys);

    await db.verseDao.deleteByMinLessonIndex(classroomId, contentSerial, lessonIndex);
    await db.verseKeyDao.deleteByMinLessonIndex(classroomId, contentSerial, lessonIndex);
    await db.verseDao.insertListOrFail(insertVerses);
    await db.verseKeyDao.insertListOrFail(insertVerseKeys);
    await db.textVersionDao.delete(TextVersionType.lessonContent, deleteLk.id!);
    return true;
  }

  @transaction
  Future<bool> addLesson(LessonShow lessonShow, int lessonIndex, Map<String, dynamic> out) async {
    int lessonKeyId = lessonShow.lessonKeyId;
    LessonKey? baseLk = await getById(lessonKeyId);
    if (baseLk == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["cant find the lesson data($lessonKeyId)"]));
      return false;
    }
    out['lessonKey'] = baseLk;
    return await interAddLesson(
      lessonContent: baseLk.content,
      bookSerial: baseLk.contentSerial,
      chapterIndex: lessonIndex,
    );
  }

  @transaction
  Future<bool> addFirstLesson(
    int contentSerial,
  ) async {
    return await interAddLesson(
      lessonContent: "{}",
      bookSerial: contentSerial,
      chapterIndex: 0,
    );
  }

  Future<bool> interAddLesson({
    required String lessonContent,
    required int bookSerial,
    required int chapterIndex,
  }) async {
    var now = DateTime.now();
    int classroomId = Classroom.curr;
    Lesson newLesson = Lesson(
      classroomId: classroomId,
      contentSerial: bookSerial,
      lessonIndex: chapterIndex,
    );
    LessonKey newLessonKey = LessonKey(
      classroomId: classroomId,
      contentSerial: bookSerial,
      lessonIndex: chapterIndex,
      version: 1,
      content: lessonContent,
      contentVersion: 1,
    );
    TextVersion newTextVersion = TextVersion(
      t: TextVersionType.lessonContent,
      version: 1,
      reason: TextVersionReason.editor,
      text: lessonContent,
      createTime: now,
    );

    Content? content = await db.contentDao.getBySerial(classroomId, bookSerial);
    if (content == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["cant find the content data($bookSerial)"]));
      return false;
    }
    var lessons = await db.lessonDao.findByMinLessonIndex(classroomId, bookSerial, chapterIndex);
    var lessonKeys = await findByMinLessonIndex(classroomId, bookSerial, chapterIndex);
    List<Lesson> insertLessons = [newLesson];
    List<LessonKey> insertLessonKeys = [newLessonKey];
    for (var v in lessons) {
      v.lessonIndex++;
      insertLessons.add(v);
    }
    for (var v in lessonKeys) {
      v.lessonIndex++;
      insertLessonKeys.add(v);
    }
    var verses = await db.verseDao.findByMinLessonIndex(classroomId, bookSerial, chapterIndex);
    var verseKeys = await db.verseKeyDao.findByMinLessonIndex(classroomId, bookSerial, chapterIndex);
    List<Verse> insertVerses = [];
    List<VerseKey> insertVerseKeys = [];
    for (var v in verses) {
      var lessonIndex = v.lessonIndex + 1;
      v.sort = content.sort * 10000000000 + lessonIndex * 100000 + v.verseIndex;
      v.lessonIndex = lessonIndex;
      insertVerses.add(v);
    }
    for (var v in verseKeys) {
      v.lessonIndex++;
      insertVerseKeys.add(v);
    }
    await deleteByMinLessonIndex(classroomId, bookSerial, chapterIndex);
    await insertOrFail(insertLessonKeys);
    int? newLessonKeyId = await getLessonKeyId(newLessonKey.classroomId, newLessonKey.contentSerial, newLessonKey.lessonIndex, newLessonKey.version);
    if (newLessonKeyId == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["cant find the newLessonKeyId by ${newLessonKey.classroomId}, ${newLessonKey.contentSerial}, ${newLessonKey.lessonIndex}, ${newLessonKey.version}"]));
      return false;
    }
    newLesson.lessonKeyId = newLessonKeyId;
    newTextVersion.id = newLessonKeyId;

    await db.lessonDao.deleteByMinLessonIndex(classroomId, bookSerial, chapterIndex);
    await db.lessonDao.insertOrFail(insertLessons);

    await db.verseDao.deleteByMinLessonIndex(classroomId, bookSerial, chapterIndex);
    await db.verseKeyDao.deleteByMinLessonIndex(classroomId, bookSerial, chapterIndex);
    await db.verseDao.insertListOrFail(insertVerses);
    await db.verseKeyDao.insertListOrFail(insertVerseKeys);
    await db.textVersionDao.insertOrFail(newTextVersion);

    return true;
  }
}
