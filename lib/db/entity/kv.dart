// entity/kv.dart

import 'package:floor/floor.dart';

enum K {
  settingsI18n,
  settingsTheme,
}

@entity
class Kv {
  @primaryKey
  final K key;
  final String value;

  Kv(this.key, this.value);
}
