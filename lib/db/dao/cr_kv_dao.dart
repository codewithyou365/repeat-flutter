// dao/cr_kv_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';

@dao
abstract class CrKvDao {
  late AppDatabase db;

  @Query('SELECT * FROM CrKv where `k` in (:k)')
  Future<List<CrKv>> find(List<CrK> k);

  @Query("SELECT * FROM CrKv where `k`=:k")
  Future<CrKv?> one(CrK k);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrReplace(CrKv kv);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertsOrReplace(List<CrKv> kv);
}
