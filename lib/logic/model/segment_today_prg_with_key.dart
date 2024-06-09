import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';

@Entity(tableName: "")
class SegmentTodayPrgWithKey extends SegmentTodayPrg {
  @primaryKey
  final String k;

  SegmentTodayPrgWithKey(
    super.segmentKeyId,
    super.type,
    super.sort,
    super.progress,
    super.viewTime,
    super.reviewCount,
    super.reviewCreateDate,
    super.finish,
    this.k,
  );
}
