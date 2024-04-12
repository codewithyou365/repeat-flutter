// entity/schedule_today.dart

import 'package:floor/floor.dart';

@entity
class ScheduleToday {
  @primaryKey
  final String key;
  final int sort;

  final DateTime fullTime;

  ScheduleToday(this.key, this.sort, this.fullTime);

  static List<ScheduleToday> create(List<String> keys) {
    List<ScheduleToday> ret = [];
    for (int i = 0; i < keys.length; i++) {
      ret.add(ScheduleToday(keys[i], 0, DateTime.now()));
    }
    return ret;
  }
}
