import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';

@Entity(tableName: "")
class SegmentOverallPrgWithKey extends SegmentOverallPrg {
  @primaryKey
  String contentName;
  int lessonIndex;
  int segmentIndex;

  SegmentOverallPrgWithKey(
    super.segmentKeyId,
    super.classroomId,
    super.contentSerial,
    super.next,
    super.progress,
    this.contentName,
    this.lessonIndex,
    this.segmentIndex,
  );

  String toKey() {
    return '$contentName-${lessonIndex + 1}-${segmentIndex + 1}';
  }
}
