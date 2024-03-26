// entity/settings.dart

import 'package:floor/floor.dart';

@entity
class Settings {
  @primaryKey
  final int id;

  final String themeMode;
  final String i18n;
  Settings(this.id, this.themeMode, this.i18n);
}

