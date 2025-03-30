import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(tableName: "")
class SegmentShow {
  @primaryKey
  final String key;
  final String contentName;
  final String segmentContent;
  final String segmentNote;
  final int lessonIndex;
  final int segmentIndex;
  final Date next;
  final int progress;
  final bool missing;

  SegmentShow(
    this.key,
    this.contentName,
    this.segmentContent,
    this.segmentNote,
    this.lessonIndex,
    this.segmentIndex,
    this.next,
    this.progress,
    this.missing,
  );

  String toShortPos() {
    return '${lessonIndex + 1}|${segmentIndex + 1}';
  }

  int toSort() {
    return lessonIndex * 100000 + segmentIndex;
  }
}
