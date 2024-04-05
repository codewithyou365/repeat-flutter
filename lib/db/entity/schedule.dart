// entity/schedule.dart

import 'package:floor/floor.dart';

@entity
class Schedule {
  @primaryKey
  final String key;

  final int progress;

  Schedule(this.key, this.progress);
}
