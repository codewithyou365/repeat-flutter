// dao/cache_file_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/cache_file.dart';

@dao
abstract class CacheFileDao {
  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  @Query('SELECT id FROM CacheFile WHERE url = :url')
  Future<int?> getId(String url);

  @Query('SELECT path FROM CacheFile WHERE id = :id')
  Future<String?> getPath(int id);

  @Query('SELECT * FROM CacheFile WHERE url = :url')
  Future<CacheFile?> one(String url);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertCacheFile(CacheFile data);

  @Query('UPDATE OR ABORT CacheFile SET msg=:msg WHERE id = :id')
  Future<void> updateCacheFile(int id, String msg);

  @Query('UPDATE OR ABORT CacheFile SET count=:count,total=:total WHERE id = :id')
  Future<void> updateProgressById(int id, int count, int total);

  @Query('UPDATE OR ABORT CacheFile SET count=total,path=:path WHERE id = :id')
  Future<void> updateFinish(int id, String path);

  @transaction
  Future<int> insert(String url) async {
    await forUpdate();
    var id = await getId(url);
    if (id != null) {
      return id;
    }
    var cache = CacheFile(url, "");
    insertCacheFile(cache);
    id = await getId(url);
    return id!;
  }
}
