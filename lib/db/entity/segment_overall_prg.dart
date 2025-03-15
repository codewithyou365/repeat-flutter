// entity/segment_overall_prg.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['classroomId', 'segmentHash'],
  indices: [
    Index(value: ['classroomId', 'next', 'progress']),
    Index(value: ['classroomId', 'contentSerial']),
  ],
)
class SegmentOverallPrg {
  final int classroomId;
  String segmentHash;

  final int contentSerial;
  final Date next;

  final int progress;

  SegmentOverallPrg(
    this.classroomId,
    this.segmentHash,
    this.contentSerial,
    this.next,
    this.progress,
  );
}
