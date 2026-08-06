import 'package:floor/floor.dart';
import 'package:repeat_flutter/logic/book_help.dart';

@Entity(tableName: "")
class ChapterShow {
  @primaryKey
  final int chapterId;
  final int bookId;
  final int bookSort;
  String chapterContent;
  int chapterContentVersion;
  final int chapterIndex;

  ChapterShow({
    required this.chapterId,
    required this.bookId,
    required this.bookSort,
    required this.chapterContent,
    required this.chapterContentVersion,
    required this.chapterIndex,
  });

  /// 书名不是数据库列了，JOIN 不出来，按 bookId 从书本缓存里查。
  /// [ChapterHelp.tryGen] 会先把 [BookHelp] 生成好，这里一定拿得到。
  String get bookName => BookHelp.getCache(bookId)?.name ?? '';

  String toPos() {
    return '$bookName-${chapterIndex + 1}';
  }

  int toSort() {
    return bookSort * 10000000000 + chapterIndex * 100000;
  }
}
