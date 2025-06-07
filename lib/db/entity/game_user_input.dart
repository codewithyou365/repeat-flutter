// entity/game_user_verse.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'contentSerial', 'chapterIndex', 'verseIndex']),
    Index(value: ['verseKeyId']),
    Index(value: ['createDate']),
    Index(value: ['gameId', 'gameUserId', 'time']),
  ],
)
class GameUserInput {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final int gameId;
  final int gameUserId;
  final int time;
  final int verseKeyId;
  final int classroomId;
  final int contentSerial;
  final int chapterIndex;
  final int verseIndex;

  final String input;
  final String output;
  final int createTime;
  final Date createDate;

  GameUserInput(
    this.gameId,
    this.gameUserId,
    this.time,
    this.verseKeyId,
    this.classroomId,
    this.contentSerial,
    this.chapterIndex,
    this.verseIndex,
    this.input,
    this.output,
    this.createTime,
    this.createDate, {
    this.id,
  });

  static empty() => GameUserInput(0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, Date(0));

  isEmpty() => gameId == 0;
}
