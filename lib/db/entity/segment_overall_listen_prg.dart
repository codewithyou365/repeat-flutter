// entity/segment_overall_prg.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

import 'segment_overall_prg.dart';

@Entity(
  primaryKeys: ['segmentKeyId'],
  indices: [
    Index(value: ['next', 'progress']),
  ],
)
class SegmentOverallListenPrg {
  int segmentKeyId;

  final Date next;

  final int progress;

  SegmentOverallListenPrg(
    this.segmentKeyId,
    this.next,
    this.progress,
  );

  static SegmentOverallListenPrg from(SegmentOverallPrg d) {
    return SegmentOverallListenPrg(
      d.segmentKeyId,
      d.next,
      d.progress,
    );
  }
}
