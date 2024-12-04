import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment_review.dart';

@Entity(tableName: "")
class SegmentReviewWithKey extends SegmentReview {
  @primaryKey
  String contentName;
  int lessonIndex;
  int segmentIndex;

  SegmentReviewWithKey(
    super.createDate,
    super.segmentKeyId,
    super.classroomId,
    super.contentSerial,
    super.count,
    this.contentName,
    this.lessonIndex,
    this.segmentIndex,
  );
}
