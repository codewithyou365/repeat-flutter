// dao/assistive_touch_action_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/assistive_touch_action.dart';

@dao
abstract class AssistiveTouchActionDao {
  @Query('SELECT * FROM AssistiveTouchAction WHERE classroomId=:classroomId ORDER BY sort ASC, id ASC')
  Future<List<AssistiveTouchAction>> findAll(int classroomId);

  @Query('SELECT * FROM AssistiveTouchAction WHERE id=:id')
  Future<AssistiveTouchAction?> getById(int id);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insert(AssistiveTouchAction action);

  @Update(onConflict: OnConflictStrategy.fail)
  Future<void> update(AssistiveTouchAction action);

  @Query('DELETE FROM AssistiveTouchAction WHERE id=:id')
  Future<void> deleteById(int id);
}
