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
  int chapterId;
  int chapterIndex;
  int verseIndex;
  Date learnDate;
  int progress;

  VerseShow({
    required this.verseId,
    required this.bookId,
    required this.bookName,
    required this.bookSort,
    required this.verseContent,
    required this.verseContentVersion,
    required this.chapterId,
    required this.chapterIndex,
    required this.verseIndex,
    required this.learnDate,
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

  VerseShow copy() {
    return VerseShow(
      verseId: verseId,
      bookId: bookId,
      bookName: bookName,
      bookSort: bookSort,
      verseContent: verseContent,
      verseContentVersion: verseContentVersion,
      chapterId: chapterId,
      chapterIndex: chapterIndex,
      verseIndex: verseIndex,
      learnDate: learnDate,
      progress: progress,
    );
  }
}
