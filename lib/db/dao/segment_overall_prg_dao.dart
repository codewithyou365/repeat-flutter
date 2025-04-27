import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment_overall_prg.dart';

@dao
abstract class SegmentOverallPrgDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(SegmentOverallPrg entity);

}
