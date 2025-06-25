import 'package:floor/floor.dart';

@Entity(tableName: "")
class ChapterShow {
  @primaryKey
  final int chapterId;
  final int bookId;
  final String bookName;
  final int bookSort;
  String chapterContent;
  int chapterContentVersion;
  final int chapterIndex;

  ChapterShow({
    required this.chapterId,
    required this.bookId,
    required this.bookName,
    required this.bookSort,
    required this.chapterContent,
    required this.chapterContentVersion,
    required this.chapterIndex,
  });

  String toPos() {
    return '$bookName-${chapterIndex + 1}';
  }

  int toSort() {
    return bookSort * 10000000000 + chapterIndex * 100000;
  }
}
