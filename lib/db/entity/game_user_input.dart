// entity/game_user_segment.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'contentSerial', 'lessonIndex', 'segmentIndex']),
    Index(value: ['segmentKeyId']),
    Index(value: ['createDate']),
    Index(value: ['gameId', 'gameUserId']),
  ],
)
class GameUserInput {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final int gameId;
  final int gameUserId;

  final int segmentKeyId;
  final int classroomId;
  final int contentSerial;
  final int lessonIndex;
  final int segmentIndex;

  final String input;
  final String output;
  final int createTime;
  final Date createDate;

  GameUserInput(
    this.gameId,
    this.gameUserId,
    this.segmentKeyId,
    this.classroomId,
    this.contentSerial,
    this.lessonIndex,
    this.segmentIndex,
    this.input,
    this.output,
    this.createTime,
    this.createDate, {
    this.id,
  });
}
