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

  @Query('DELETE FROM ChapterContentVersion '
      ' WHERE chapterId not in (:chapterIds)')
  Future<void> remainByChapterIds(List<int> chapterIds);

  @Query('''
  SELECT c.* FROM ChapterContentVersion c
  INNER JOIN (
    SELECT chapterId, MAX(version) AS max_version
    FROM ChapterContentVersion
    WHERE bookId = :bookId
    GROUP BY chapterId
  ) sub
  ON c.chapterId = sub.chapterId AND c.version = sub.max_version
''')
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
    List<ChapterContentVersion> needToInserts = toChapterContentVersion(list);
    if (needToInserts.isNotEmpty) {
      await insertOrFail(needToInserts);
    }
  }

  List<ChapterContentVersion> toChapterContentVersion(List<Chapter> list) {
    List<ChapterContentVersion> ret = [];
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
      ret.add(tv);
    }
    return ret;
  }

  Future<void> reimport(int bookId, List<Chapter> inserts, List<Chapter> updates) async {
    List<int> remainChapterIds = updates.map((v) => v.id!).toList();
    await remainByChapterIds(remainChapterIds);

    List<ChapterContentVersion> needToInserts = toChapterContentVersion(inserts);
    List<ChapterContentVersion> contentVersion = await currVersionList(bookId);
    Map<int, ChapterContentVersion> idToContentVersion = {for (var v in contentVersion) v.chapterId: v};
    for (var v in updates) {
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
  }
}
