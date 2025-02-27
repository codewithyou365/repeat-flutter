import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['classroomId', 'createDate'],

)
class TimeStats {
  final int classroomId;
  final Date createDate;
  final int createTime;
  final int duration;

  TimeStats(
    this.classroomId,
    this.createDate,
    this.createTime,
    this.duration,
  );
}
