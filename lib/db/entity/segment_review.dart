// entity/segment_review.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['createDate', 'key'],
)
class SegmentReview {
  final Date createDate;
  final String key;

  final int count;

  SegmentReview(this.createDate, this.key, this.count);

  static List<SegmentReview> from(List<String> keys) {
    final now = Date.from(DateTime.now());
    return keys.map((key) => SegmentReview(now, key, 0)).toList();
  }
}
