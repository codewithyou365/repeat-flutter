import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(
  primaryKeys: ['verseKeyId', 'type', 'createDate'],
  indices: [
    Index(value: ['classroomId', 'bookSerial']),
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
  final int bookSerial;

  VerseStats(
    this.verseKeyId,
    this.type,
    this.createDate,
    this.createTime,
    this.classroomId,
    this.bookSerial,
  );
}
