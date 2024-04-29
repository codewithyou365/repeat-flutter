// entity/segment_current_prg.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['g', 'k', 'learnOrReview'],
)
class SegmentCurrentPrg {
  final String g;
  final String k;

  bool learnOrReview;

  int sort;

  int progress;

  DateTime viewTime;

  SegmentCurrentPrg(
    this.k,
    this.learnOrReview,
    this.sort,
    this.progress,
    this.viewTime, {
    this.g = "en",
  });
}
