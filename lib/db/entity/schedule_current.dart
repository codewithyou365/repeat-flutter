// entity/schedule.dart

import 'package:floor/floor.dart';

@entity
class ScheduleCurrent {
  @primaryKey
  final String key;

  int sort;

  int progress;

  DateTime viewTime;

  ScheduleCurrent(this.key, this.sort, this.progress, this.viewTime);
}
