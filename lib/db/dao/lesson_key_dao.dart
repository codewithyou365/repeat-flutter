// dao/lesson_key_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/lesson.dart';
import 'package:repeat_flutter/db/entity/lesson_key.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/text_version.dart';
import 'package:repeat_flutter/logic/model/segment_key_id.dart';

@dao
abstract class LessonKeyDao {
  late AppDatabase db;

  @Query('SELECT ifnull(sum(Lesson.lessonKeyId is null),0) missingCount'
      ' FROM LessonKey'
      ' JOIN Content ON Content.id=:contentId'
      ' LEFT JOIN Lesson ON Lesson.lessonKeyId=LessonKey.id')
  Future<int?> getMissingCount(int contentId);

  @Query('SELECT * FROM LessonKey WHERE classroomId=:classroomId and contentSerial=:contentSerial')
  Future<List<LessonKey>> find(int classroomId, int contentSerial);

  @Query('SELECT id,k FROM LessonKey WHERE classroomId=:classroomId and contentSerial=:contentSerial')
  Future<List<KeyId>> findKeyId(int classroomId, int contentSerial);

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
      var keyIds = await findKeyId(Classroom.curr, contentSerial);
      keyToId = {for (var keyId in keyIds) keyId.k: keyId.id};
      for (var newLesson in newLessonKeys) {
        int? id = keyToId[newLesson.k];
        if (id != null) {
          newLesson.id = id;
        }
      }
    }

    List<TextVersion> oldContentVersion = await db.textVersionDao.getTextForLessonContent(oldLessonIds);
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
    return newLessonKeys.length < keyToId.length;
  }
}
