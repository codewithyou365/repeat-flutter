// dao/Kv_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/kv.dart';

@dao
abstract class KvDao {
  @Query('SELECT * FROM Kv where `k` in (:k)')
  Future<List<Kv>> find(List<K> k);

  @Query("SELECT * FROM Kv where `k`=:k")
  Future<Kv?> one(K k);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertKv(Kv kv);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertKvs(List<Kv> kv);
}
