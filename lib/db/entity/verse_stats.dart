import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['verseKeyId', 'type', 'createDate'],
  indices: [
    Index(value: ['bookId']),
    Index(value: ['classroomId', 'createDate']),
    Index(value: ['classroomId', 'createTime']),
  ],
)
class VerseStats {
  final int verseKeyId;
  final int type;
  final Date createDate;
  final int createTime;
  final int classroomId;
  final int bookId;
  final int chapterKeyId;
  VerseStats({
    required this.verseKeyId,
    required this.type,
    required this.createDate,
    required this.createTime,
    required this.classroomId,
    required this.bookId,
    required this.chapterKeyId,
  });
}
