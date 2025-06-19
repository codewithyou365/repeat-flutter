import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse_content_version.dart';

@dao
abstract class VerseContentVersionDao {
  @Query('SELECT * '
      ' FROM VerseContentVersion'
      ' WHERE bookId=:bookId')
  Future<List<VerseContentVersion>> list(int bookId);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(VerseContentVersion entity);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertOrIgnore(VerseContentVersion entity);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertsOrIgnore(List<VerseContentVersion> entities);

  @Query('DELETE FROM VerseContentVersion'
      ' WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);
}
