// entity/segment_current_prg.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['crn', 'k', 'learnOrReview'],
)
class SegmentCurrentPrg {
  final String crn;
  final String k;

  bool learnOrReview;

  int sort;

  int progress;

  DateTime viewTime;

  SegmentCurrentPrg(
    this.crn,
    this.k,
    this.learnOrReview,
    this.sort,
    this.progress,
    this.viewTime,
  );
}
