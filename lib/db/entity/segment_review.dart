// entity/segment_review.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['createDate', 'segmentKeyId'],
)
class SegmentReview {
  final Date createDate;
  final int segmentKeyId;
  final int classroomId;
  final int materialSerial;

  final int count;

  SegmentReview(
    this.createDate,
    this.segmentKeyId,
    this.classroomId,
    this.materialSerial,
    this.count,
  );
}
