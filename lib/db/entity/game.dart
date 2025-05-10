// entity/game.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'contentSerial', 'lessonIndex', 'segmentIndex']),
    Index(value: ['segmentKeyId']),
    Index(value: ['createDate']),
  ],
)
class Game {
  @primaryKey
  final int id;

  final int time;
  final String segmentContent;

  final int segmentKeyId;
  final int classroomId;
  final int contentSerial;
  final int lessonIndex;
  final int segmentIndex;

  final bool finish;
  final int createTime;
  final Date createDate;

  Game({
    required this.id,
    required this.time,
    required this.segmentContent,
    required this.segmentKeyId,
    required this.classroomId,
    required this.contentSerial,
    required this.lessonIndex,
    required this.segmentIndex,
    required this.finish,
    required this.createTime,
    required this.createDate,
  });
}
