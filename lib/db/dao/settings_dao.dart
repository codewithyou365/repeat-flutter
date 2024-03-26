// dao/settings_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/settings.dart';

@dao
abstract class SettingsDao {
  @Query('SELECT * FROM Settings limit 1')
  Future<Settings?> one();

  @insert
  Future<void> insertSettings(Settings settings);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateSettings(Settings settings);
}