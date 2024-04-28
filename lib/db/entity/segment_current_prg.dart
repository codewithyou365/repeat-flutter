// entity/segment_current_prg.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['group', 'key', 'learnOrReview'],
)
class SegmentCurrentPrg {
  final String group;
  final String key;

  bool learnOrReview;

  int sort;

  int progress;

  DateTime viewTime;

  SegmentCurrentPrg(
    this.key,
    this.learnOrReview,
    this.sort,
    this.progress,
    this.viewTime, {
    this.group = "en",
  });
}
