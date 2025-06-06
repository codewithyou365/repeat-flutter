import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse_overall_prg.dart';

@dao
abstract class VerseOverallPrgDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(VerseOverallPrg entity);

}
