import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(tableName: "")
class SegmentShow {
  @primaryKey
  final int segmentKeyId;
  String key;
  final int contentId;
  final String contentName;
  String segmentContent;
  int segmentContentVersion;
  String segmentNote;
  int segmentNoteVersion;
  int lessonIndex;
  int segmentIndex;
  Date next;
  int progress;
  final bool missing;

  SegmentShow(
    this.segmentKeyId,
    this.key,
    this.contentId,
    this.contentName,
    this.segmentContent,
    this.segmentContentVersion,
    this.segmentNote,
    this.segmentNoteVersion,
    this.lessonIndex,
    this.segmentIndex,
    this.next,
    this.progress,
    this.missing,
  );

  String toPos() {
    return '$contentName-${lessonIndex + 1}|${segmentIndex + 1}';
  }

  int toSort() {
    return lessonIndex * 100000 + segmentIndex;
  }
}
