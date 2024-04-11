// entity/schedule.dart

import 'package:floor/floor.dart';

@entity
class ScheduleCurrent {
  @primaryKey
  final String key;

  final String url;
  final int sort;

  final int progress;

  final DateTime errorTime;

  ScheduleCurrent(this.key, this.url, this.sort, this.progress, this.errorTime);
}
