import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse_overall_prg.dart';

@Entity(tableName: "")
class VerseOverallPrgWithKey extends VerseOverallPrg {
  @primaryKey
  String contentName;
  int lessonIndex;
  int verseIndex;

  VerseOverallPrgWithKey(
    super.verseKeyId,
    super.classroomId,
    super.contentSerial,
    super.next,
    super.progress,
    this.contentName,
    this.lessonIndex,
    this.verseIndex,
  );

  String toKey() {
    return '$contentName-${lessonIndex + 1}-${verseIndex + 1}';
  }
}
