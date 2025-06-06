import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(tableName: "")
class VerseShow {
  @primaryKey
  final int verseKeyId;
  String k;
  final int contentId;
  final String contentName;
  final int contentSerial;
  final int contentSort;
  String verseContent;
  int verseContentVersion;
  String verseNote;
  int verseNoteVersion;
  int lessonIndex;
  int verseIndex;
  Date next;
  int progress;
  final bool missing;

  VerseShow({
    required this.verseKeyId,
    required this.k,
    required this.contentId,
    required this.contentName,
    required this.contentSerial,
    required this.contentSort,
    required this.verseContent,
    required this.verseContentVersion,
    required this.verseNote,
    required this.verseNoteVersion,
    required this.lessonIndex,
    required this.verseIndex,
    required this.next,
    required this.progress,
    required this.missing,
  });

  String toLessonPos() {
    return '$contentName-${lessonIndex + 1}';
  }
  String toVersePos() {
    return '-${verseIndex + 1}';
  }

  int toSort() {
    return contentSort * 10000000000 + lessonIndex * 100000 + verseIndex;
  }
}
