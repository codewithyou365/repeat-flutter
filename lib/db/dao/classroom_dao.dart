import 'dart:convert' as convert;

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:repeat_flutter/common/num.dart';

@dao
abstract class ClassroomDao {
  static const String emptyContent = '{}';

  late AppDatabase db;

  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  @Query('SELECT * FROM Classroom WHERE hide=false ORDER BY sort')
  Future<List<Classroom>> getAllClassroom();

  @Query('SELECT ifnull(id,0) FROM Classroom WHERE id=:id')
  Future<int?> existById(int id);

  @Query('SELECT ifnull(max(id),0) FROM Classroom')
  Future<int?> getMaxId();

  @Query('SELECT ifnull(sort,0) FROM Classroom WHERE sort=:sort')
  Future<int?> existBySort(int sort);

  @Query('SELECT ifnull(max(sort),0) FROM Classroom')
  Future<int?> getMaxSort();

  @Query('SELECT * FROM Classroom WHERE name=:name')
  Future<Classroom?> getClassroom(String name);

  @Query('SELECT * FROM Classroom WHERE id=:id')
  Future<Classroom?> getById(int id);

  @Query('UPDATE Classroom set content=:content,contentVersion=:contentVersion'
      ' WHERE Classroom.id=:id')
  Future<void> updateContentVersion(int id, String content, int contentVersion);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertClassroom(Classroom entity);

  @Query('UPDATE Classroom set hide=true'
      ' WHERE Classroom.id=:id')
  Future<void> hide(int id);

  @Query('UPDATE Classroom set name=:name'
      ' WHERE Classroom.id=:id')
  Future<void> updateName(int id, String name);

  @Query('UPDATE Classroom set sort=:sort'
      ' WHERE Classroom.id=:id')
  Future<void> updateSort(int id, int sort);

  @transaction
  Future<void> reorder(List<int> orderedIds) async {
    await forUpdate();
    for (var i = 0; i < orderedIds.length; i++) {
      await updateSort(orderedIds[i], -(i + 1));
    }
    for (var i = 0; i < orderedIds.length; i++) {
      await updateSort(orderedIds[i], i);
    }
  }

  @Query('UPDATE Classroom set hide=false'
      ' WHERE Classroom.id=:id')
  Future<void> showClassroom(int id);

  @Query('DELETE FROM Classroom WHERE id=:id')
  Future<void> deleteById(int id);

  @transaction
  Future<void> deleteAll(int classroomId) async {
    await _deleteData(classroomId);
    await deleteById(classroomId);
  }

  /// 清空课堂里的所有数据（书本、学习进度、游戏、提示…），课堂本身留着，内容回到空。
  /// 导入失败时用来回滚：课堂是用户自己建的，不能连课堂一起删。
  @transaction
  Future<void> clearAll(int classroomId) async {
    await _deleteData(classroomId);
    final classroom = await getById(classroomId);
    if (classroom != null) {
      await updateContentVersion(classroomId, emptyContent, classroom.contentVersion + 1);
    }
  }

  Future<void> _deleteData(int classroomId) async {
    await db.bookDao.deleteByClassroomId(classroomId);
    await db.bookContentVersionDao.deleteByClassroomId(classroomId);
    await db.chapterDao.deleteByClassroomId(classroomId);
    await db.chapterContentVersionDao.deleteByClassroomId(classroomId);
    await db.crKvDao.deleteByClassroomId(classroomId);
    await db.gameKvDao.deleteByClassroomId(classroomId);
    await db.gameDao.deleteByClassroomId(classroomId);
    await db.tipDao.deleteByClassroomId(classroomId);
    await db.timeStatsDao.deleteByClassroomId(classroomId);
    await db.verseDao.deleteByClassroomId(classroomId);
    await db.verseContentVersionDao.deleteByClassroomId(classroomId);
    await db.verseReviewDao.deleteByClassroomId(classroomId);
    await db.verseStatsDao.deleteByClassroomId(classroomId);
    await db.verseTodayPrgDao.deleteByClassroomId(classroomId);
  }

  @transaction
  Future<Classroom> add(String name) async {
    await forUpdate();
    var ret = await getClassroom(name);
    if (ret != null) {
      if (ret.hide == false) {
        Snackbar.show(I18nKey.labelDataDuplication.tr);
        return ret;
      }
      await showClassroom(ret.id);
    } else {
      var maxId = await getMaxId();
      var id = await Num.getNextId(maxId, existById1: existById);
      var maxSort = await getMaxSort();
      var sort = await Num.getNextId(maxSort, existById1: existBySort);
      ret = Classroom(id, name, sort, false, emptyContent, 0);
      await insertClassroom(ret);
    }
    return ret;
  }

  /// 对标 BookDao.updateBookContent：先校验 JSON、没变就不动、变了才 +1 版本。
  /// 课堂内容没有历史表，网络编辑的原文由 EditBookHistory 留底。
  ///
  /// 事务提交之后才发事件，跟 BookDao.updateBookContent 一样：在事务里发的话，
  /// 监听方回头查库读到的还是旧内容。
  Future<Classroom> updateContent(int classroomId, String content) async {
    final ret = await innerUpdateContent(classroomId, content);
    EventBus().publish<int>(EventTopic.updateClassroomContent, classroomId);
    return ret;
  }

  @transaction
  Future<Classroom> innerUpdateContent(int classroomId, String content) async {
    Classroom? classroom = await getById(classroomId);
    if (classroom == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(['classroom']));
      return Classroom(0, '', 0, true, emptyContent, 0);
    }

    try {
      Map<String, dynamic> contentM = convert.jsonDecode(content);
      content = convert.jsonEncode(contentM);
    } catch (e) {
      Snackbar.showAndThrow(e.toString());
      return classroom;
    }

    if (classroom.content == content) {
      return classroom;
    }

    await updateContentVersion(classroomId, content, classroom.contentVersion + 1);
    classroom.content = content;
    classroom.contentVersion++;
    return classroom;
  }
}
