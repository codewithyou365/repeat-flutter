// entity/schedule.dart

import 'package:floor/floor.dart';

@Entity(indices: [
  Index(value: ['next']),
])
class SegmentOverallPrg {
  @primaryKey
  final String key;

  final int progress;

  final DateTime next;
  final int sort;

  SegmentOverallPrg(this.key, this.progress, this.next, this.sort);
}
