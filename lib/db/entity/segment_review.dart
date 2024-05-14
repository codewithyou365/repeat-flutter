// entity/segment_review.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['crn', 'createDate', 'k'],
)
class SegmentReview {
  final String crn;
  final Date createDate;
  final String k;

  final int count;

  SegmentReview(
    this.crn,
    this.createDate,
    this.k,
    this.count,
  );
}
