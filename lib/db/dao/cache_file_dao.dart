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
}