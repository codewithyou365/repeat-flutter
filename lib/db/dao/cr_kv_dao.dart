// dao/cr_kv_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';

@dao
abstract class CrKvDao {
  late AppDatabase db;

  @Query('SELECT * FROM CrKv where `k` in (:k)')
  Future<List<CrKv>> find(List<CrK> k);

  @Query("SELECT * FROM CrKv where classroomId=:classroomId and `k`=:k")
  Future<CrKv?> one(int classroomId, CrK k);

  @Query("SELECT CAST(value as INTEGER) FROM CrKv WHERE classroomId=:classroomId and k=:k")
  Future<int?> getInt(int classroomId, CrK k);

  @Query("SELECT value FROM CrKv WHERE classroomId=:classroomId and k=:k")
  Future<String?> getString(int classroomId, CrK k);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrReplace(CrKv kv);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertsOrReplace(List<CrKv> kv);

  @Query('DELETE FROM CrKv WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);
}
