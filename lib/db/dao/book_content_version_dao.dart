import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/book_content_version.dart';
import 'package:repeat_flutter/db/entity/content_version.dart';

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

  Future<void> import(Book book) async {
    BookContentVersion insertBookContentVersion = BookContentVersion(
      classroomId: book.classroomId,
      bookId: book.id!,
      version: 1,
      reason: VersionReason.import,
      content: book.content,
      createTime: DateTime.now(),
    );
    await insertOrFail(insertBookContentVersion);
  }

  Future<BookContentVersion?> reimport(Book book) async {
    BookContentVersion? oldBookContentVersion = await one(book.id!, book.contentVersion);

    if (oldBookContentVersion == null || oldBookContentVersion.content != book.content) {
      var maxVersion = book.contentVersion;
      var nextVersion = maxVersion + 1;
      BookContentVersion insertBookContentVersion = BookContentVersion(
        classroomId: book.classroomId,
        bookId: book.id!,
        version: nextVersion,
        reason: VersionReason.import,
        content: book.content,
        createTime: DateTime.now(),
      );
      await insertOrFail(insertBookContentVersion);
      return insertBookContentVersion;
    }
    return null;
  }
}
