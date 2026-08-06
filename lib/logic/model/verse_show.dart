import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/logic/book_help.dart';

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

  /// 书名不是数据库列了，JOIN 不出来，按 bookId 从书本缓存里查。
  /// [VerseHelp.tryGen] 会先把 [BookHelp] 生成好，这里一定拿得到。
  String get bookName => BookHelp.getCache(bookId)?.name ?? '';

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
