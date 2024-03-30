// dao/cache_file_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/cache_file.dart';

@dao
abstract class CacheFileDao {
  @Query('SELECT * FROM CacheFile limit 1')
  Future<CacheFile?> one();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertCacheFile(CacheFile data);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateCacheFile(CacheFile data);

  @Query('UPDATE OR ABORT CacheFile SET count=:count,total=:total WHERE url = :url')
  Future<void> updateProgressByUrl(String url, int count, int total);

  @Query('UPDATE OR ABORT CacheFile SET count=total WHERE url = :url')
  Future<void> updateFinish(String url);
}
