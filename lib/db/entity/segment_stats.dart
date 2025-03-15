import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['segmentHash', 'type', 'createDate'],
  indices: [
    Index(value: ['classroomId', 'contentSerial']),
    Index(value: ['classroomId', 'createDate']),
  ],
)
class SegmentStats {
  final int classroomId;
  final String segmentHash;
  final int type;
  final Date createDate;
  final int createTime;
  final int contentSerial;

  SegmentStats(
    this.classroomId,
    this.segmentHash,
    this.type,
    this.createDate,
    this.createTime,
    this.contentSerial,
  );
}
