// entity/schedule.dart

import 'package:floor/floor.dart';

@entity
class Schedule {
  @primaryKey
  final String key;

  //todo type

  final int progress;

  final int next;
  final int sort;

  Schedule(this.key, this.progress, this.next, this.sort);
}
