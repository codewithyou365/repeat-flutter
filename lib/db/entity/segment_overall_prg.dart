// entity/schedule.dart

import 'package:floor/floor.dart';

@Entity(indices: [
  Index(value: ['next', 'progress', 'sort']),
  Index(value: ['sort'], unique: true),
])
class SegmentOverallPrg {
  @primaryKey
  final String key;

  final DateTime next;

  final int progress;

  final int sort;

  SegmentOverallPrg(this.key, this.next, this.progress, this.sort);
}
