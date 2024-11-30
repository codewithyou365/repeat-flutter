// dao/material_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/num.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/material.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

@dao
abstract class MaterialDao {
  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  @Query('SELECT * FROM Material where classroomId=:classroomId and hide=false ORDER BY sort')
  Future<List<Material>> getAllMaterial(int classroomId);

  @Query('SELECT ifnull(max(serial),0) FROM Material WHERE classroomId=:classroomId')
  Future<int?> getMaxSerial(int classroomId);

  @Query('SELECT ifnull(serial,0) FROM Material WHERE classroomId=:classroomId and serial=:serial')
  Future<int?> existBySerial(int classroomId, int serial);

  @Query('SELECT ifnull(max(sort),0) FROM Material WHERE classroomId=:classroomId')
  Future<int?> getMaxSort(int classroomId);

  @Query('SELECT ifnull(sort,0) FROM Material WHERE classroomId=:classroomId and sort=:sort')
  Future<int?> existBySort(int classroomId, int sort);

  @Query('SELECT * FROM Material WHERE classroomId=:classroomId and name=:name')
  Future<Material?> getMaterialByName(int classroomId, String name);

  @Query('SELECT * FROM Material WHERE classroomId=:classroomId and serial=:serial')
  Future<Material?> getMaterialBySerial(int classroomId, int serial);

  @Query('SELECT * FROM Material WHERE classroomId=:classroomId and sort=:sort')
  Future<Material?> getMaterialBySort(int classroomId, int sort);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertMaterial(Material entity);

  @Query('UPDATE Material set hide=true'
      ' WHERE Material.id=:id')
  Future<void> hide(int id);

  @Query('UPDATE Material set hide=false'
      ' WHERE Material.id=:id')
  Future<void> showMaterial(int id);

  @Query('UPDATE Material set docId=:docId'
      ' WHERE Material.id=:id')
  Future<void> updateDocId(int id, int docId);

  @transaction
  Future<Material> add(String name) async {
    await forUpdate();
    var ret = await getMaterialByName(Classroom.curr, name);
    if (ret != null) {
      if (ret.hide == false) {
        Snackbar.show(I18nKey.labelDataDuplication.tr);
        return ret;
      }
      await showMaterial(ret.id!);
    } else {
      var maxSerial = await getMaxSerial(Classroom.curr);
      var serial = await Num.getNextId(maxSerial, id: Classroom.curr, existById2: existBySerial);

      var maxSort = await getMaxSort(Classroom.curr);
      var sort = await Num.getNextId(maxSort, id: Classroom.curr, existById2: existBySort);
      ret = Material(Classroom.curr, serial, name, '', 0, sort, false);
      await insertMaterial(ret);
    }
    return ret;
  }
}
