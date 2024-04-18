// entity/schedule_today.dart

import 'package:floor/floor.dart';

@entity
class SegmentTodayPrg {
  @primaryKey
  final String key;

  int sort;

  int progress;

  DateTime viewTime;

  DateTime createTime;

  SegmentTodayPrg(
    this.key,
    this.sort,
    this.progress,
    this.viewTime,
    this.createTime,
  );
}
