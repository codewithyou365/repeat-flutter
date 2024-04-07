// entity/schedule.dart

import 'package:floor/floor.dart';

@Entity(indices: [
  Index(value: ['url']),
  Index(value: ['next']),
])
class Schedule {
  @primaryKey
  final String key;

  final String url;
  final int type;

  final int progress;

  final int next;
  final int sort;

  Schedule(this.key, this.url, this.type, this.progress, this.next, this.sort);
}
