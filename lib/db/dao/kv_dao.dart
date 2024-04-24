// dao/Kv_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/kv.dart';



@dao
abstract class KvDao {
  @Query('SELECT * FROM Kv where `key` in (:key)')
  Future<List<Kv>> find(List<K> key);

  @Query('SELECT * FROM Kv where `key`=:key')
  Future<Kv?> one(K key);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertKv(Kv kv);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertKvs(List<Kv> kv);
}
