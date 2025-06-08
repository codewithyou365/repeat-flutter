import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse_overall_prg.dart';

@Entity(tableName: "")
class VerseOverallPrgWithKey extends VerseOverallPrg {
  @primaryKey
  String contentName;
  int chapterIndex;
  int verseIndex;

  VerseOverallPrgWithKey(
    super.verseKeyId,
    super.classroomId,
    super.bookSerial,
    super.next,
    super.progress,
    this.contentName,
    this.chapterIndex,
    this.verseIndex,
  );

  String toKey() {
    return '$contentName-${chapterIndex + 1}-${verseIndex + 1}';
  }
}
