import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';

@Entity(tableName: "")
class SegmentOverallPrgWithKey extends SegmentOverallPrg {
  @primaryKey
  final String crn;
  final String k;

  SegmentOverallPrgWithKey(
    super.segmentKeyId,
    super.next,
    super.progress,
    this.crn,
    this.k,
  );
}
