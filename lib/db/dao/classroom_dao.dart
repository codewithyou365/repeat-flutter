import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:repeat_flutter/common/num.dart';

@dao
abstract class ClassroomDao {
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

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertClassroom(Classroom entity);

  @Query('UPDATE Classroom set hide=true'
      ' WHERE Classroom.id=:id')
  Future<void> hide(int id);

  @Query('UPDATE Classroom set hide=false'
      ' WHERE Classroom.id=:id')
  Future<void> showClassroom(int id);

  @Query('DELETE FROM Classroom WHERE id=:id')
  Future<void> deleteById(int id);

  @transaction
  Future<void> deleteAll(int classroomId) async {
    await db.bookDao.deleteByClassroomId(classroomId);
    await db.bookContentVersionDao.deleteByClassroomId(classroomId);
    await db.chapterDao.deleteByClassroomId(classroomId);
    await db.chapterContentVersionDao.deleteByClassroomId(classroomId);
    await deleteById(classroomId);
    await db.crKvDao.deleteByClassroomId(classroomId);
    await db.gameDao.deleteByClassroomId(classroomId);
    await db.gameUserInputDao.deleteByClassroomId(classroomId);
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
      ret = Classroom(id, name, sort, false);
      await insertClassroom(ret);
    }
    return ret;
  }
}
