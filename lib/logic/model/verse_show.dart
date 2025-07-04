import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(tableName: "")
class VerseShow {
  @primaryKey
  final int verseId;
  final int bookId;
  final String bookName;
  final int bookSort;
  String verseContent;
  int verseContentVersion;
  String verseNote;
  int verseNoteVersion;
  int chapterId;
  int chapterIndex;
  int verseIndex;
  Date next;
  int progress;

  VerseShow({
    required this.verseId,
    required this.bookId,
    required this.bookName,
    required this.bookSort,
    required this.verseContent,
    required this.verseContentVersion,
    required this.verseNote,
    required this.verseNoteVersion,
    required this.chapterId,
    required this.chapterIndex,
    required this.verseIndex,
    required this.next,
    required this.progress,
  });

  String toChapterPos() {
    return '$bookName-${chapterIndex + 1}';
  }
  String toVersePos() {
    return '-${verseIndex + 1}';
  }

  int toSort() {
    return bookSort * 10000000000 + chapterIndex * 100000 + verseIndex;
  }
}
