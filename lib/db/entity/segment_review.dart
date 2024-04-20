// entity/schedule.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/logic/date_help.dart';

@Entity(indices: [
  Index(value: ['createDate']),
])
class SegmentReview {
  @primaryKey
  final String key;

  final int count;

  final int createDate;

  SegmentReview(this.key, this.count, this.createDate);

  static List<SegmentReview> from(List<String> keys) {
    final now = DateHelp.from(DateTime.now());
    return keys.map((key) => SegmentReview(key, 0, now)).toList();
  }
}
