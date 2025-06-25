import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse_overall_prg.dart';

@Entity(tableName: "")
class VerseOverallPrgWithKey extends VerseOverallPrg {
  @primaryKey
  String contentName;
  int chapterIndex;
  int verseIndex;

  VerseOverallPrgWithKey({
    required super.verseId,
    required super.classroomId,
    required super.bookId,
    required super.chapterId,
    required super.next,
    required super.progress,
    required this.contentName,
    required this.chapterIndex,
    required this.verseIndex,
  });

  String toKey() {
    return '$contentName-${chapterIndex + 1}-${verseIndex + 1}';
  }
}
