// dao/content_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/num.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

@dao
abstract class ContentDao {
  late AppDatabase db;

  @Query('SELECT * FROM Content where classroomId=:classroomId and hide=false ORDER BY sort')
  Future<List<Content>> getAllContent(int classroomId);

  @Query('SELECT max(segmentWarning) FROM Content where classroomId=:classroomId and docId!=0 and hide=false')
  Future<bool?> hasWarning(int classroomId);

  @Query('SELECT * FROM Content where classroomId=:classroomId and docId!=0 and hide=false ORDER BY sort')
  Future<List<Content>> getAllEnableContent(int classroomId);

  @Query('SELECT ifnull(max(serial),0) FROM Content WHERE classroomId=:classroomId')
  Future<int?> getMaxSerial(int classroomId);

  @Query('SELECT ifnull(serial,0) FROM Content WHERE classroomId=:classroomId and serial=:serial')
  Future<int?> existBySerial(int classroomId, int serial);

  @Query('SELECT ifnull(max(sort),0) FROM Content WHERE classroomId=:classroomId')
  Future<int?> getMaxSort(int classroomId);

  @Query('SELECT ifnull(sort,0) FROM Content WHERE classroomId=:classroomId and sort=:sort')
  Future<int?> existBySort(int classroomId, int sort);

  @Query('SELECT * FROM Content WHERE id=:id')
  Future<Content?> one(int id);

  @Query('SELECT * FROM Content WHERE classroomId=:classroomId and name=:name')
  Future<Content?> getContentByName(int classroomId, String name);

  @Query('UPDATE Content set docId=:docId,url=:url,lessonWarning=:lessonWarning,segmentWarning=:segmentWarning,updateTime=:updateTime WHERE Content.id=:id')
  Future<void> updateContent(int id, int docId, String url, bool lessonWarning, bool segmentWarning, int updateTime);

  @Query('UPDATE Content set lessonWarning=:lessonWarning,segmentWarning=:segmentWarning,updateTime=:updateTime WHERE Content.id=:id')
  Future<void> updateContentWarning(int id, bool lessonWarning, bool segmentWarning, int updateTime);

  @Query('UPDATE Content set lessonWarning=:lessonWarning,updateTime=:updateTime WHERE Content.id=:id')
  Future<void> updateContentWarningForLesson(int id, bool lessonWarning, int updateTime);

  @Query('UPDATE Content set segmentWarning=:segmentWarning,updateTime=:updateTime WHERE Content.id=:id')
  Future<void> updateContentWarningForSegment(int id, bool segmentWarning, int updateTime);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertContent(Content entity);

  @Query('UPDATE Content set hide=true'
      ' WHERE Content.id=:id')
  Future<void> hide(int id);

  @Query('UPDATE Content set hide=false'
      ' WHERE Content.id=:id')
  Future<void> showContent(int id);

  @Query('UPDATE Content set docId=:docId'
      ' WHERE Content.id=:id')
  Future<void> updateDocId(int id, int docId);

  @transaction
  Future<Content> add(String name) async {
    await db.lockDao.forUpdate();
    var ret = await getContentByName(Classroom.curr, name);
    if (ret != null) {
      if (ret.hide == false) {
        Snackbar.show(I18nKey.labelDataDuplication.tr);
        return ret;
      }
      await showContent(ret.id!);
    } else {
      var maxSerial = await getMaxSerial(Classroom.curr);
      var serial = await Num.getNextId(maxSerial, id: Classroom.curr, existById2: existBySerial);

      var maxSort = await getMaxSort(Classroom.curr);
      var sort = await Num.getNextId(maxSort, id: Classroom.curr, existById2: existBySort);

      var now = DateTime.now().millisecondsSinceEpoch;
      ret = Content(
        classroomId: Classroom.curr,
        serial: serial,
        name: name,
        desc: '',
        docId: 0,
        url: '',
        sort: sort,
        hide: false,
        lessonWarning: false,
        segmentWarning: false,
        createTime: now,
        updateTime: now,
      );
      await insertContent(ret);
    }
    return ret;
  }
}
