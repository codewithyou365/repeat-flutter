import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'contentSerial']),
    Index(value: ['classroomId', 'createDate']),
    Index(value: ['classroomId', 'createTime']),
  ],
)
class SegmentStats {
  @PrimaryKey(autoGenerate: true)
  int? id;
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
    this.contentSerial, {
    this.id,
  });
}
