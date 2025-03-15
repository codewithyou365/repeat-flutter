// entity/segment_review.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['createDate', 'classroomId', 'segmentHash'],
  indices: [
    Index(value: ['classroomId', 'contentSerial']),
    Index(value: ['classroomId', 'createDate']),
  ],
)
class SegmentReview {
  final Date createDate;
  final int classroomId;
  final String segmentHash;

  final int contentSerial;

  final int count;

  SegmentReview(
    this.createDate,
    this.classroomId,
    this.segmentHash,
    this.contentSerial,
    this.count,
  );
}
