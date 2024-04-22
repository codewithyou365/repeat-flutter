import 'package:floor/floor.dart';

@Entity(tableName: "")
class SegmentReviewContentInDb {
  @primaryKey
  final String key;
  final int sort;
  final String createDate;

  SegmentReviewContentInDb(this.key, this.sort, this.createDate);
}
