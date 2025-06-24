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

  TimeStats({
    required this.classroomId,
    required this.createDate,
    required this.createTime,
    required this.duration,
  });
}
