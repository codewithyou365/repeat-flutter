// entity/segment_overall_prg.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['segmentKeyId'],
  indices: [
    Index(value: ['next', 'progress']),
  ],
)
class SegmentOverallPrg {
  int segmentKeyId;

  final int classroomId;
  final int materialSerial;
  final Date next;

  final int progress;

  SegmentOverallPrg(
    this.segmentKeyId,
    this.classroomId,
    this.materialSerial,
    this.next,
    this.progress,
  );
}
