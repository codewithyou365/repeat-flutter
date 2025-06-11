import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(tableName: "")
class ChapterShow {
  @primaryKey
  final int chapterKeyId;
  final int bookId;
  final String bookName;
  final int bookSort;
  String chapterContent;
  int chapterContentVersion;
  final int chapterIndex;
  final bool missing;

  ChapterShow({
    required this.chapterKeyId,
    required this.bookId,
    required this.bookName,
    required this.bookSort,
    required this.chapterContent,
    required this.chapterContentVersion,
    required this.chapterIndex,
    required this.missing,
  });

  String toPos() {
    return '$bookName-${chapterIndex + 1}';
  }

  int toSort() {
    return bookSort * 10000000000 + chapterIndex * 100000;
  }
}
