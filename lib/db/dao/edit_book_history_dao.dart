// dao/edit_book_history_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/edit_book_history.dart';

@dao
abstract class EditBookHistoryDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(EditBookHistory entity);

  @Query('SELECT * FROM EditBookHistory WHERE bookId = :bookId ORDER BY commitDate DESC LIMIT :limit')
  Future<List<EditBookHistory>> getPaginatedList(int bookId, int limit);

  @Query('SELECT * FROM EditBookHistory WHERE bookId = :bookId AND id < :lastId ORDER BY commitDate DESC LIMIT :limit')
  Future<List<EditBookHistory>> getPaginatedListWithLastId(int bookId, int lastId, int limit);

  @Query('SELECT COUNT(*) FROM EditBookHistory WHERE bookId = :bookId')
  Future<int?> getCount(int bookId);
}
