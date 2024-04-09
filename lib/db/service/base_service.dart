import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/id99999.dart';
import 'package:repeat_flutter/db/entity/lock.dart';

@dao
abstract class BaseService {
  @Query('SELECT * FROM Id99999 limit 1')
  Future<Id99999?> getId99999();

  @Query('SELECT * FROM Lock limit 1')
  Future<Lock?> getLock();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertId99999(List<Id99999> entities);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertLock(Lock entity);

  @transaction
  Future<void> initData() async {
    var id99999 = await getId99999();
    if (id99999 == null) {
      List<Id99999> ids = [];
      for (var i = 1; i <= 99999; i++) {
        ids.add(Id99999(i));
      }
      await insertId99999(ids);
    }
    var lock = await getLock();
    if (lock == null) {
      await insertLock(Lock(1));
    }
  }
}
