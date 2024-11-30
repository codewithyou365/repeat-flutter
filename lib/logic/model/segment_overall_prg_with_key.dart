import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';

@Entity(tableName: "")
class SegmentOverallPrgWithKey extends SegmentOverallPrg {
  @primaryKey
  String materialName;
  int lessonIndex;
  int segmentIndex;

  SegmentOverallPrgWithKey(
    super.segmentKeyId,
    super.classroomId,
    super.materialSerial,
    super.next,
    super.progress,
    this.materialName,
    this.lessonIndex,
    this.segmentIndex,
  );
}
