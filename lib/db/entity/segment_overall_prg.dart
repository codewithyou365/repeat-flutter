// entity/segment_overall_prg.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['crn', 'k'],
  indices: [
    Index(value: ['next', 'progress']),
  ],
)
class SegmentOverallPrg {
  final String crn;
  final String k;

  final Date next;

  final int progress;

  SegmentOverallPrg(
    this.crn,
    this.k,
    this.next,
    this.progress,
  );
}
