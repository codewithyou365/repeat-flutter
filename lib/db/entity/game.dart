// entity/game.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  indices: [
    Index(value: ['classroomId']),
    Index(value: ['bookId']),
    Index(value: ['verseKeyId']),
    Index(value: ['createDate']),
  ],
)
class Game {
  @primaryKey
  final int id;

  final int time;
  final String verseContent;

  final int verseKeyId;
  final int classroomId;
  final int bookId;
  final int chapterKeyId;

  final bool finish;
  final int createTime;
  final Date createDate;

  Game({
    required this.id,
    required this.time,
    required this.verseContent,
    required this.verseKeyId,
    required this.classroomId,
    required this.bookId,
    required this.chapterKeyId,
    required this.finish,
    required this.createTime,
    required this.createDate,
  });
}
