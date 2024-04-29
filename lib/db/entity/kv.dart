// entity/kv.dart

import 'package:floor/floor.dart';

enum K {
  settingsI18n,
  settingsTheme,
  todayLearnCreateDate,
}

@Entity(primaryKeys: ['g', 'k'])
class Kv {
  final String g;
  final K k;
  final String value;

  Kv(
    this.k,
    this.value, {
    this.g = "",
  });
}
