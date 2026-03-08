// dao/game_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game.dart';

@dao
abstract class GameDao {
  late AppDatabase db;

  @Query('SELECT * FROM Game WHERE id=:id')
  Future<Game?> getById(int id);

  @Query('SELECT id FROM Game WHERE classroomId=:classroomId AND name=:name')
  Future<int?> getIdByName(int classroomId, String name);

  @Query('SELECT * FROM Game WHERE classroomId=:classroomId')
  Future<List<Game>> getByClassroomId(int classroomId);

  @Query('DELETE FROM Game WHERE classroomId=:classroomId AND name=:name')
  Future<void> deleteByName(int classroomId, String name);

  @Query('DELETE FROM Game WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('DELETE FROM Game WHERE bookId=:bookId')
  Future<void> deleteByBookId(int bookId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrReplace(Game kv);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateOrReplace(Game kv);
}
