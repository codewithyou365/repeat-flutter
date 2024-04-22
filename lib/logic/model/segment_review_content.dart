import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/entity/segment.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

@Entity(tableName: "")
class SegmentReviewContentInDb {
  @primaryKey
  final String key;
  final int sort;
  final String createDate;

  SegmentReviewContentInDb(this.key, this.sort, this.createDate);
}
