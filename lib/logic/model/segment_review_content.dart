import 'package:floor/floor.dart';

@Entity(tableName: "")
class SegmentReviewContentInDb {
  @primaryKey
  final String key;
  final int sort;
  final int reviewCount;
  final String reviewCreateDate;

  SegmentReviewContentInDb(this.key, this.sort, this.reviewCount, this.reviewCreateDate);
}
