import 'package:floor/floor.dart';

@Entity(tableName: "")
class SegmentReviewContentInDb {
  @primaryKey
  final String k;
  final int sort;
  final int reviewCount;
  final String reviewCreateDate;

  SegmentReviewContentInDb(this.k, this.sort, this.reviewCount, this.reviewCreateDate);
}
