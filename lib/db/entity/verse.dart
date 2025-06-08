// entity/verse.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['verseKeyId'],
  indices: [
    Index(value: ['classroomId', 'sort'], unique: true),
    Index(value: ['classroomId', 'bookSerial', 'chapterIndex', 'verseIndex'], unique: true),
  ],
)
class Verse {
  int verseKeyId;

  final int classroomId;
  final int bookSerial;
  int chapterIndex;
  int verseIndex;

  int sort;

  Verse({
    required this.verseKeyId,
    required this.classroomId,
    required this.bookSerial,
    required this.chapterIndex,
    required this.verseIndex,
    required this.sort,
  });

  String toStringKey() {
    return '$classroomId|$bookSerial|$chapterIndex|$verseIndex';
  }
}
