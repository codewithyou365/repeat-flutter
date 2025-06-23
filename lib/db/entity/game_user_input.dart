// entity/game_user_verse.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  indices: [
    Index(value: ['classroomId']),
    Index(value: ['bookId']),
    Index(value: ['chapterKeyId']),
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
  final int bookId;
  final int chapterKeyId;

  final String input;
  final String output;
  final int createTime;
  final Date createDate;

  GameUserInput({
    required this.gameId,
    required this.gameUserId,
    required this.time,
    required this.verseKeyId,
    required this.classroomId,
    required this.bookId,
    required this.chapterKeyId,
    required this.input,
    required this.output,
    required this.createTime,
    required this.createDate,
    this.id,
  });

  static GameUserInput empty() => GameUserInput(
        gameId: 0,
        gameUserId: 0,
        time: 0,
        verseKeyId: 0,
        classroomId: 0,
        bookId: 0,
        chapterKeyId: 0,
        input: '',
        output: '',
        createTime: 0,
        createDate: Date(0),
      );

  bool isEmpty() => gameId == 0;
}
