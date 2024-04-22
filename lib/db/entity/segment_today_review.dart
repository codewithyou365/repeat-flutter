// entity/segment_today_review.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['createDate', 'key'],
)
class SegmentTodayReview {
  final Date createDate;
  final String key;

  SegmentTodayReview(this.createDate, this.key);

  static List<SegmentTodayReview> from(List<int> createDates, String key) {
    return createDates.map((date) => SegmentTodayReview(Date(date), key)).toList();
  }
}
