// entity/schedule.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(indices: [
  Index(value: ['createDate']),
])
class SegmentReview {
  @primaryKey
  final String key;

  final int count;

  final Date createDate;

  SegmentReview(this.key, this.count, this.createDate);

  static List<SegmentReview> from(List<String> keys) {
    final now = Date.from(DateTime.now());
    return keys.map((key) => SegmentReview(key, 0, now)).toList();
  }
}
