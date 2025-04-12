import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(tableName: "")
class LessonShow {
  @primaryKey
  final int lessonKeyId;
  final int contentId;
  final String contentName;
  final int contentSort;
  String lessonContent;
  int lessonContentVersion;
  final int lessonIndex;
  final bool missing;

  LessonShow({
    required this.lessonKeyId,
    required this.contentId,
    required this.contentName,
    required this.contentSort,
    required this.lessonContent,
    required this.lessonContentVersion,
    required this.lessonIndex,
    required this.missing,
  });

  String toPos() {
    return '$contentName-${lessonIndex + 1}';
  }

  int toSort() {
    return contentSort * 10000000000 + lessonIndex * 100000;
  }
}
