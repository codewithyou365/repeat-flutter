// entity/verse.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['verseKeyId'],
  indices: [
    Index(value: ['classroomId', 'sort'], unique: true),
    Index(value: ['classroomId', 'contentSerial', 'chapterIndex', 'verseIndex'], unique: true),
  ],
)
class Verse {
  int verseKeyId;

  final int classroomId;
  final int contentSerial;
  int chapterIndex;
  int verseIndex;

  int sort;

  Verse({
    required this.verseKeyId,
    required this.classroomId,
    required this.contentSerial,
    required this.chapterIndex,
    required this.verseIndex,
    required this.sort,
  });

  String toStringKey() {
    return '$classroomId|$contentSerial|$chapterIndex|$verseIndex';
  }
}
