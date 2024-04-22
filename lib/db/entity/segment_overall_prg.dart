// entity/segment_overall_prg.dart

import 'package:floor/floor.dart';

@Entity(indices: [
  Index(value: ['next', 'progress']),
])
class SegmentOverallPrg {
  @primaryKey
  final String key;

  final DateTime next;

  final int progress;

  SegmentOverallPrg(this.key, this.next, this.progress);
}
