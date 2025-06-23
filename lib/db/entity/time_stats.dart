import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  indices: [
    Index(value: ['bookId']),
    Index(value: ['chapterKeyId']),
    Index(value: ['verseKeyId']),
  ],
  primaryKeys: ['classroomId', 'createDate'],
)
class TimeStats {
  final int classroomId;
  final int bookId;
  final int chapterKeyId;
  final int verseKeyId;
  final Date createDate;
  final int createTime;
  final int duration;

  TimeStats({
    required this.classroomId,
    required this.bookId,
    required this.chapterKeyId,
    required this.verseKeyId,
    required this.createDate,
    required this.createTime,
    required this.duration,
  });
}
