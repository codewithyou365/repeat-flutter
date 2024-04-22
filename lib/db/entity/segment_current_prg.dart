// entity/segment_current_prg.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['key', 'learnOrReview'],
)
class SegmentCurrentPrg {
  final String key;

  bool learnOrReview;

  int sort;

  int progress;

  DateTime viewTime;

  DateTime createTime;

  SegmentCurrentPrg(
    this.key,
    this.learnOrReview,
    this.sort,
    this.progress,
    this.viewTime,
    this.createTime,
  );
}
