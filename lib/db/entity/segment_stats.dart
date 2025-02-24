import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['segmentKeyId', 'type', 'createDate'],
  indices: [
    Index(value: ['classroomId', 'contentSerial']),
    Index(value: ['classroomId', 'createDate']),
  ],
)
class SegmentStats {
  final int segmentKeyId;
  final int type;
  final Date createDate;
  final int createTime;
  final int classroomId;
  final int contentSerial;

  SegmentStats(
    this.segmentKeyId,
    this.type,
    this.createDate,
    this.createTime,
    this.classroomId,
    this.contentSerial,
  );
}
