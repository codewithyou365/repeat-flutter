import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment_review.dart';

@Entity(tableName: "")
class SegmentReviewWithKey extends SegmentReview {
  @primaryKey
  final String crn;
  final String k;

  SegmentReviewWithKey(
    super.createDate,
    super.segmentKeyId,
    super.count,
    this.crn,
    this.k,
  );
}
