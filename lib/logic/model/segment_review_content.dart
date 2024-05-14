import 'package:floor/floor.dart';

@Entity(tableName: "")
class SegmentReviewContentInDb {
  @primaryKey
  final String crn;
  final String k;
  final int sort;
  final int reviewCount;
  final String reviewCreateDate;

  SegmentReviewContentInDb(this.crn, this.k, this.sort, this.reviewCount, this.reviewCreateDate);
}
