import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(tableName: "")
class BookShow {
  @primaryKey
  final int bookId;
  final String name;
  final int sort;
  String bookContent;
  int bookContentVersion;

  BookShow({
    required this.bookId,
    required this.name,
    required this.sort,
    required this.bookContent,
    required this.bookContentVersion,
  });

  String toPos() {
    return name;
  }

  int toSort() {
    return sort;
  }
}
