// entity/segment_today_review.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['crn', 'createDate', 'k', 'count'],
)
class SegmentTodayReview {
  final String crn;
  final Date createDate;
  final String k;
  final int count;
  final bool finish;

  SegmentTodayReview(
    this.crn,
    this.createDate,
    this.k,
    this.count,
    this.finish,
  );
}
