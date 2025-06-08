// entity/chapter_key.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'bookSerial', 'chapterIndex', 'version'], unique: true),
  ],
)
class ChapterKey {
  @PrimaryKey(autoGenerate: true)
  int? id;

  final int classroomId;
  final int bookSerial;
  int chapterIndex;
  int version;
  final String content;
  int contentVersion;

  ChapterKey({
    this.id,
    required this.classroomId,
    required this.bookSerial,
    required this.chapterIndex,
    required this.version,
    required this.content,
    required this.contentVersion,
  });

  String get k {
    return "$classroomId-$bookSerial-$chapterIndex";
  }
}
