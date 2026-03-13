// dao/Kv_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';

@dao
abstract class KvDao {
  late AppDatabase db;

  @Query('SELECT * FROM Kv where `k` in (:k)')
  Future<List<Kv>> find(List<K> k);

  @Query("SELECT * FROM Kv where `k`=:k")
  Future<Kv?> one(K k);

  @Query("SELECT CAST(value as INTEGER) FROM Kv where `k`=:k")
  Future<int?> getInt(K k);

  @Query("SELECT value FROM Kv where `k`=:k")
  Future<String?> getStr(K k);

  @Query('DELETE FROM Kv where `k` in (:k)')
  Future<void> delete(List<K> k);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrReplace(Kv kv);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertKvs(List<Kv> kv);

  Future<int> getIntWithDefault(K k, int value) async {
    var ret = await getInt(k);
    if (ret == null) {
      return value;
    }
    return ret;
  }

  Future<void> clearAtAppStart() async {
    await delete([
      K.mediaSharePort,
      K.gameServerPort,
      K.bookEditorPort,
      K.materialSharePort,
    ]);
  }
}
