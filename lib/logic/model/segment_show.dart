import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(tableName: "")
class SegmentShow {
  @primaryKey
  final int segmentKeyId;
  String key;
  final String contentName;
  String segmentContent;
  String segmentNote;
  int lessonIndex;
  int segmentIndex;
  Date next;
  int progress;
  final bool missing;

  SegmentShow(
    this.segmentKeyId,
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
