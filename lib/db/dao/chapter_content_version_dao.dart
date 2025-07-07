import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/chapter.dart';
import 'package:repeat_flutter/db/entity/chapter_content_version.dart';
import 'package:repeat_flutter/db/entity/content_version.dart';

@dao
abstract class ChapterContentVersionDao {
  late AppDatabase db;

  @Query('SELECT * '
      ' FROM ChapterContentVersion'
      ' WHERE chapterId=:chapterId')
  Future<List<ChapterContentVersion>> list(int chapterId);

  @Query('SELECT ChapterContentVersion.* '
      ' FROM Chapter'
      ' JOIN ChapterContentVersion ON ChapterContentVersion.chapterId=Chapter.id'
      '  AND ChapterContentVersion.version=Chapter.contentVersion'
      ' WHERE ChapterContentVersion.bookId=:bookId')
  Future<List<ChapterContentVersion>> currVersionList(int bookId);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(List<ChapterContentVersion> entities);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertOrIgnore(ChapterContentVersion entity);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertsOrIgnore(List<ChapterContentVersion> entities);

  @Query('DELETE FROM ChapterContentVersion'
      ' WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('DELETE FROM ChapterContentVersion'
      ' WHERE bookId=:bookId')
  Future<void> deleteByBookId(int bookId);

  @Query('DELETE FROM ChapterContentVersion'
      ' WHERE chapterId=:chapterId')
  Future<void> deleteByChapterId(int chapterId);

  Future<void> import(List<Chapter> list) async {
    List<ChapterContentVersion> needToInserts = [];
    for (var v in list) {
      var tv = ChapterContentVersion(
        classroomId: v.classroomId,
        bookId: v.bookId,
        chapterId: v.id!,
        version: 1,
        reason: VersionReason.import,
        content: v.content,
        createTime: DateTime.now(),
      );
      needToInserts.add(tv);
    }
    if (needToInserts.isNotEmpty) {
      await insertOrFail(needToInserts);
    }
  }

  Future<List<ChapterContentVersion>> reimport(int bookId, List<Chapter> list) async {
    List<ChapterContentVersion> needToInserts = [];
    List<ChapterContentVersion> contentVersion = await currVersionList(bookId);
    Map<int, ChapterContentVersion> idToContentVersion = {for (var v in contentVersion) v.chapterId: v};
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
          chapterId: v.id!,
          version: currVersionNumber,
          reason: VersionReason.reimport,
          content: v.content,
          createTime: DateTime.now(),
        );
        needToInserts.add(tv);
      }
    }
    if (needToInserts.isNotEmpty) {
      await insertOrFail(needToInserts);
    }
    return needToInserts;
  }
}
