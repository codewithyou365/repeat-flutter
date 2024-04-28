// entity/segment_overall_prg.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['group', 'key'],
  indices: [
    Index(value: ['next', 'progress']),
  ],
)
class SegmentOverallPrg {
  final String group;
  final String key;

  final Date next;

  final int progress;

  SegmentOverallPrg(
    this.key,
    this.next,
    this.progress, {
    this.group = "en",
  });
}
