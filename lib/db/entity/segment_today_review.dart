// entity/segment_today_review.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['createDate', 'key', 'count'],
)
class SegmentTodayReview {
  final Date createDate;
  final String key;
  final int count;
  final bool finish;

  SegmentTodayReview(this.createDate, this.key, this.count, this.finish);

  static List<SegmentTodayReview> from(List<int> createDates, String key, int count) {
    return createDates.map((date) => SegmentTodayReview(Date(date), key, count, false)).toList();
  }
}
