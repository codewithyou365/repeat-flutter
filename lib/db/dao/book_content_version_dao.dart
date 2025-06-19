import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/book_content_version.dart';

@dao
abstract class BookContentVersionDao {
  @Query('SELECT * '
      ' FROM BookContentVersion'
      ' WHERE bookId=:bookId')
  Future<List<BookContentVersion>> list(int bookId);

  @Query('SELECT * '
      ' FROM BookContentVersion'
      ' WHERE bookId=:bookId'
      '  AND version=:version')
  Future<BookContentVersion?> one(int bookId, int version);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(BookContentVersion entity);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertOrIgnore(BookContentVersion entity);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertsOrIgnore(List<BookContentVersion> entities);

  @Query('DELETE FROM BookContentVersion'
      ' WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);
}
