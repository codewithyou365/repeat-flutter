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

  static List<SegmentReview> fromMap(Map<String, String> keyToCreateDates) {
    List<SegmentReview> ret = [];
    keyToCreateDates.forEach((key, value) {
      List<String> dates = value.split(',');
      for (String date in dates) {
        ret.add(SegmentReview(Date(int.parse(date)), key, 0));
      }
    });
    return ret;
  }

  static List<SegmentReview> from(List<String> keys) {
    final now = Date.from(DateTime.now());
    return keys.map((key) => SegmentReview(now, key, 0)).toList();
  }
}
