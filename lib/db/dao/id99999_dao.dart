// dao/id99999_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/id99999.dart';

@dao
abstract class Id99999Dao {
  @Query('SELECT * FROM Id99999 limit 1')
  Future<Id99999?> one();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSchedules(List<Id99999> entities);
}
