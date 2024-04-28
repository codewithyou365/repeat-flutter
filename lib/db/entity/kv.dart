// entity/kv.dart

import 'package:floor/floor.dart';

enum K {
  settingsI18n,
  settingsTheme,
  todayLearnCreateDate,
}

@Entity(primaryKeys: ['group', 'key'])
class Kv {
  final String group;
  final K key;
  final String value;

  Kv(
    this.key,
    this.value, {
    this.group = "",
  });
}
