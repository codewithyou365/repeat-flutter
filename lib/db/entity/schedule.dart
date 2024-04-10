// entity/schedule.dart

import 'package:floor/floor.dart';

@Entity(indices: [
  Index(value: ['url']),
  Index(value: ['next']),
])
class Schedule {
  @primaryKey
  final String key;

  final String indexUrl;
  final String url;
  final int type;

  final int progress;

  final DateTime next;
  final int sort;

  Schedule(this.key, this.indexUrl, this.url, this.type, this.progress, this.next, this.sort);

  static List<Schedule> create(List<String> keys) {
    List<Schedule> ret = [];
    for (int i = 0; i < keys.length; i++) {
      ret.add(Schedule(keys[i], '', '', 0, 0, DateTime.now(), 0));
    }
    return ret;
  }
}
