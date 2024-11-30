import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/lock.dart';

@dao
abstract class BaseDao {
  @Query('SELECT * FROM Lock limit 1')
  Future<Lock?> getLock();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertLock(Lock entity);
}
