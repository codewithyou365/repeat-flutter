import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

@Entity(tableName: "")
class SegmentShow {
  @primaryKey
  final int segmentKeyId;
  String k;
  final int contentId;
  final String contentName;
  final int contentSerial;
  final int contentSort;
  String segmentContent;
  int segmentContentVersion;
  String segmentNote;
  int segmentNoteVersion;
  int lessonIndex;
  int segmentIndex;
  Date next;
  int progress;
  final bool missing;

  SegmentShow({
    required this.segmentKeyId,
    required this.k,
    required this.contentId,
    required this.contentName,
    required this.contentSerial,
    required this.contentSort,
    required this.segmentContent,
    required this.segmentContentVersion,
    required this.segmentNote,
    required this.segmentNoteVersion,
    required this.lessonIndex,
    required this.segmentIndex,
    required this.next,
    required this.progress,
    required this.missing,
  });

  String toLessonPos() {
    return '$contentName-${lessonIndex + 1}';
  }
  String toSegmentPos() {
    return '-${segmentIndex + 1}';
  }

  int toSort() {
    return contentSort * 10000000000 + lessonIndex * 100000 + segmentIndex;
  }
}
