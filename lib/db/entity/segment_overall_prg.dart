// entity/segment_overall_prg.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['segmentKeyId'],
  indices: [
    Index(value: ['classroomId', 'next', 'progress']),
    Index(value: ['classroomId', 'contentSerial']),
  ],
)
class SegmentOverallPrg {
  int segmentKeyId;

  final int classroomId;
  final int contentSerial;
  final Date next;

  final int progress;

  SegmentOverallPrg(
    this.segmentKeyId,
    this.classroomId,
    this.contentSerial,
    this.next,
    this.progress,
  );
}
