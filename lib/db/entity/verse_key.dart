// entity/verse_key.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'bookSerial', 'chapterIndex', 'verseIndex', 'version'], unique: true),
    Index(value: ['classroomId', 'bookSerial', 'k'], unique: true),
  ],
)
class VerseKey {
  @PrimaryKey(autoGenerate: true)
  int? id;

  final int classroomId;
  final int bookSerial;
  int chapterIndex;
  int verseIndex;
  int version;
  final String k;
  final String content;
  int contentVersion;
  final String note;
  int noteVersion;

  VerseKey({
    required this.classroomId,
    required this.bookSerial,
    required this.chapterIndex,
    required this.verseIndex,
    required this.version,
    required this.k,
    required this.content,
    required this.contentVersion,
    required this.note,
    required this.noteVersion,
    this.id,
  });
}
