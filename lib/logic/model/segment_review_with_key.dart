import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment_review.dart';

@Entity(tableName: "")
class SegmentReviewWithKey extends SegmentReview {
  @primaryKey
  String materialName;
  int lessonIndex;
  int segmentIndex;

  SegmentReviewWithKey(
    super.createDate,
    super.segmentKeyId,
    super.classroomId,
    super.materialSerial,
    super.count,
    this.materialName,
    this.lessonIndex,
    this.segmentIndex,
  );
}
