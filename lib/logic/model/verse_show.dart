import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/logic/model/verse_brief.dart';

@Entity(tableName: "")
class VerseShow {
  @primaryKey
  final int verseId;
  final int bookId;
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
    required this.bookSort,
    required this.verseContent,
    required this.verseContentVersion,
    required this.chapterId,
    required this.chapterIndex,
    required this.verseIndex,
    required this.learnDate,
    required this.progress,
  });

  int toSort() {
    return verseSortOf(bookSort, chapterIndex, verseIndex);
  }

  VerseShow copy() {
    return VerseShow(
      verseId: verseId,
      bookId: bookId,
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
