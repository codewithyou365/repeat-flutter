import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(tableName: "")
class ChapterShow {
  @primaryKey
  final int chapterKeyId;
  final int contentId;
  final String contentName;
  final int contentSort;
  String chapterContent;
  int chapterContentVersion;
  final int chapterIndex;
  final bool missing;

  ChapterShow({
    required this.chapterKeyId,
    required this.contentId,
    required this.contentName,
    required this.contentSort,
    required this.chapterContent,
    required this.chapterContentVersion,
    required this.chapterIndex,
    required this.missing,
  });

  String toPos() {
    return '$contentName-${chapterIndex + 1}';
  }

  int toSort() {
    return contentSort * 10000000000 + chapterIndex * 100000;
  }
}
