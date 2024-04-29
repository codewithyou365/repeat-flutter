// entity/segment_review.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['g', 'createDate', 'k'],
)
class SegmentReview {
  final String g;
  final Date createDate;
  final String k;

  final int count;

  SegmentReview(
    this.createDate,
    this.k,
    this.count, {
    this.g = "en",
  });

  static List<SegmentReview> fromMap(Map<String, String> keyToCreateDates) {
    List<SegmentReview> ret = [];
    keyToCreateDates.forEach((k, value) {
      List<String> dates = value.split(',');
      for (String date in dates) {
        ret.add(SegmentReview(Date(int.parse(date)), k, 0));
      }
    });
    return ret;
  }

  static List<SegmentReview> from(List<String> keys) {
    final now = Date.from(DateTime.now());
    return keys.map((k) => SegmentReview(now, k, 0)).toList();
  }
}
