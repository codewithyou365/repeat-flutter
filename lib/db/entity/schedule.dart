// entity/schedule.dart

import 'package:floor/floor.dart';

@Entity(indices: [
  Index(value: ['next']),
])
class Schedule {
  @primaryKey
  final String key;

  final int indexFileId;
  final int mediaFileId;

  final int lessonIndex;
  final int segmentIndex;

  final int progress;

  final DateTime next;
  final int sort;

  Schedule(this.key, this.indexFileId, this.mediaFileId, this.lessonIndex, this.segmentIndex, this.progress, this.next, this.sort);

  static List<Schedule> create(List<String> keys) {
    List<Schedule> ret = [];
    for (int i = 0; i < keys.length; i++) {
      ret.add(Schedule(keys[i], 0, 0, 0, 0, 0, DateTime.now(), 0));
    }
    return ret;
  }
}
