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
  final String mediaHash;
  final String aStart;
  final String aEnd;
  final String w;

  final int segmentKeyId;
  final int classroomId;
  final int contentSerial;
  final int lessonIndex;
  final int segmentIndex;

  final bool finish;
  final int createTime;
  final Date createDate;

  Game(
    this.id,
    this.time,
    this.mediaHash,
    this.aStart,
    this.aEnd,
    this.w,
    this.segmentKeyId,
    this.classroomId,
    this.contentSerial,
    this.lessonIndex,
    this.segmentIndex,
    this.finish,
    this.createTime,
    this.createDate,
  );
}
