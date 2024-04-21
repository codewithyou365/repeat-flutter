// entity/kv.dart

import 'package:floor/floor.dart';

@entity
class Kv {
  @primaryKey
  final String key;
  final String value;

  Kv(this.key, this.value);
}

