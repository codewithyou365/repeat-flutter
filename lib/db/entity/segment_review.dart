// entity/segment_review.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['createDate', 'segmentKeyId'],
  indices: [
    Index(value: ['classroomId', 'contentSerial']),
    Index(value: ['classroomId', 'createDate']),
  ],
)
class SegmentReview {
  final Date createDate;
  final int segmentKeyId;
  final int classroomId;
  final int contentSerial;

  final int count;

  SegmentReview(
    this.createDate,
    this.segmentKeyId,
    this.classroomId,
    this.contentSerial,
    this.count,
  );
}
