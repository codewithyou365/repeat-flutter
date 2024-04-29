// entity/segment_today_review.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['g', 'createDate', 'k', 'count'],
)
class SegmentTodayReview {
  final String g;
  final Date createDate;
  final String k;
  final int count;
  final bool finish;

  SegmentTodayReview(
    this.createDate,
    this.k,
    this.count,
    this.finish, {
    this.g = "en",
  });

  static List<SegmentTodayReview> from(List<int> createDates, String k, int count) {
    return createDates.map((date) => SegmentTodayReview(Date(date), k, count, false)).toList();
  }
}
