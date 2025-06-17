import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';

@dao
abstract class VerseTodayPrgDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(VerseTodayPrg entity);

  @Query('SELECT * FROM VerseTodayPrg where classroomId=:classroomId and verseKeyId=:verseKeyId and type=:type')
  Future<VerseTodayPrg?> one(int classroomId, int verseKeyId, int type);

  @Query('DELETE FROM VerseTodayPrg WHERE id=:id')
  Future<void> delete(int id);

  @Query('DELETE FROM VerseTodayPrg WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);
}
