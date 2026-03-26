// dao/tip_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/tip.dart';

@dao
abstract class TipDao {
  late AppDatabase db;

  @Query('SELECT * FROM Tip WHERE id=:id')
  Future<Tip?> getById(int id);

  @Query('SELECT id FROM Tip WHERE bookId=:bookId AND t=:type')
  Future<int?> getIdByType(int bookId, String type);

  @Query('SELECT * FROM Tip WHERE classroomId=:classroomId ORDER BY id DESC')
  Future<List<Tip>> getByClassroomId(int classroomId);

  @Query('DELETE FROM Tip WHERE bookId=:bookId AND t=:type')
  Future<void> deleteByType(int bookId, String type);

  @Query('DELETE FROM Tip WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('DELETE FROM Tip WHERE bookId=:bookId')
  Future<void> deleteByBookId(int bookId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrReplace(Tip kv);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateOrReplace(Tip kv);
}
