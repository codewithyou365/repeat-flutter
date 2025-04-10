import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/lock.dart';

@dao
abstract class LockDao {
  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  @Query('SELECT * FROM Lock limit 1')
  Future<Lock?> getLock();

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertLock(Lock entity);
}
