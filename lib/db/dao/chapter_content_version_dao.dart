import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/chapter_key.dart';
import 'package:repeat_flutter/db/entity/chapter_content_version.dart';
import 'package:repeat_flutter/db/entity/content_version.dart';

@dao
abstract class ChapterContentVersionDao {
  late AppDatabase db;

  @Query('SELECT * '
      ' FROM ChapterContentVersion'
      ' WHERE chapterKeyId=:chapterKeyId')
  Future<List<ChapterContentVersion>> list(int chapterKeyId);

  @Query('SELECT ChapterContentVersion.* '
      ' FROM ChapterKey'
      ' JOIN ChapterContentVersion ON ChapterContentVersion.chapterKeyId=ChapterKey.id'
      '  AND ChapterContentVersion.version=ChapterKey.contentVersion'
      ' WHERE ChapterContentVersion.bookId=:bookId')
  Future<List<ChapterContentVersion>> currVersionList(int bookId);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(ChapterContentVersion entity);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertOrIgnore(ChapterContentVersion entity);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertsOrIgnore(List<ChapterContentVersion> entities);

  @Query('DELETE FROM ChapterContentVersion'
      ' WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('DELETE FROM ChapterContentVersion'
      ' WHERE chapterKeyId=:chapterKeyId')
  Future<void> deleteByChapterKeyId(int chapterKeyId);

  Future<List<ChapterContentVersion>> import(List<ChapterKey> list, int bookId) async {
    List<ChapterContentVersion> insertValues = [];
    List<ChapterContentVersion> contentVersion = await currVersionList(bookId);
    Map<int, ChapterContentVersion> idToContentVersion = {for (var v in contentVersion) v.chapterKeyId: v};
    for (var v in list) {
      int id = v.id!;
      String content = v.content;
      ChapterContentVersion? version = idToContentVersion[id];
      if (version == null || version.content != content) {
        int currVersionNumber = 1;
        if (version != null) {
          currVersionNumber = version.version + 1;
        }
        var tv = ChapterContentVersion(
          classroomId: v.classroomId,
          bookId: v.bookId,
          chapterKeyId: v.id!,
          version: currVersionNumber,
          reason: VersionReason.import,
          content: v.content,
          createTime: DateTime.now(),
        );
        insertValues.add(tv);
      }
    }
    if (insertValues.isNotEmpty) {
      await insertsOrIgnore(insertValues);
    }
    return insertValues;
  }
}
