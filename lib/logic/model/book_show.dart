import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/book.dart';

@Entity(tableName: "")
class BookShow {
  @primaryKey
  final int bookId;
  final int classroomId;
  final int sort;
  String bookContent;
  int bookContentVersion;

  BookShow({
    required this.bookId,
    required this.classroomId,
    required this.sort,
    required this.bookContent,
    required this.bookContentVersion,
  });

  /// 书名不是数据库列，就在 [bookContent] 的 'n' 里（见 [Book.name]）。
  /// 这一行本来就带着 content，直接解析，不用 SQL 的 json_extract ——
  /// JSON1 扩展要 Android 11 才有，minSdk 24 的机器上没有。
  String get name => Book.nameOf(bookContent);

  String toPos() {
    return name;
  }

  int toSort() {
    return sort;
  }
}
