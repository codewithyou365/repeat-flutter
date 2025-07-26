import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/content_version.dart';
import 'package:repeat_flutter/db/entity/verse.dart';
import 'package:repeat_flutter/db/entity/verse_content_version.dart';

@dao
abstract class VerseContentVersionDao {
  @Query('SELECT * '
      ' FROM VerseContentVersion'
      ' WHERE verseId=:verseId')
  Future<List<VerseContentVersion>> list(int verseId);

  @Query('''
  SELECT c.* FROM VerseContentVersion c
  INNER JOIN (
    SELECT verseId, MAX(version) AS max_version
    FROM VerseContentVersion
    WHERE bookId = :bookId
    GROUP BY verseId
  ) sub
  ON c.verseId = sub.verseId AND c.version = sub.max_version
''')
  Future<List<VerseContentVersion>> currVersionList(int bookId);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(VerseContentVersion entity);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertsOrFail(List<VerseContentVersion> entities);

  @Query('DELETE FROM VerseContentVersion '
      ' WHERE verseId not in (:verseIds)')
  Future<void> remainByVerseIds(List<int> verseIds);

  @Query('DELETE FROM VerseContentVersion'
      ' WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('DELETE FROM VerseContentVersion'
      ' WHERE bookId=:bookId')
  Future<void> deleteByBookId(int bookId);

  @Query('DELETE FROM VerseContentVersion WHERE chapterId=:chapterId')
  Future<void> deleteByChapterId(int chapterId);

  @Query('DELETE FROM VerseContentVersion'
      ' WHERE verseId=:verseId')
  Future<void> deleteByVerseId(int verseId);

  Future<void> import(List<Verse> list) async {
    List<VerseContentVersion> needToInserts = toVerseContentVersion(list);
    if (needToInserts.isNotEmpty) {
      await insertsOrFail(needToInserts);
    }
  }

  List<VerseContentVersion> toVerseContentVersion(List<Verse> list) {
    List<VerseContentVersion> needToInserts = [];
    for (var v in list) {
      var tv = VerseContentVersion(
        classroomId: v.classroomId,
        bookId: v.bookId,
        chapterId: v.chapterId,
        verseId: v.id!,
        version: 1,
        reason: VersionReason.import,
        content: v.content,
        createTime: DateTime.now(),
      );
      needToInserts.add(tv);
    }
    return needToInserts;
  }

  Future<void> reimport(int bookId, List<Verse> inserts, List<Verse> updates) async {
    List<int> remainVerseIds = updates.map((v) => v.id!).toList();
    await remainByVerseIds(remainVerseIds);

    List<VerseContentVersion> needToInserts = toVerseContentVersion(inserts);
    List<VerseContentVersion> contentVersion = await currVersionList(bookId);
    Map<int, VerseContentVersion> idToContentVersion = {for (var v in contentVersion) v.verseId: v};
    for (var v in updates) {
      int id = v.id!;
      String content = v.content;
      VerseContentVersion? version = idToContentVersion[id];
      if (version == null || version.content != content) {
        int currVersionNumber = 1;
        if (version != null) {
          currVersionNumber = version.version + 1;
        }
        var tv = VerseContentVersion(
          classroomId: v.classroomId,
          bookId: v.bookId,
          chapterId: v.chapterId,
          verseId: v.id!,
          version: currVersionNumber,
          reason: VersionReason.reimport,
          content: v.content,
          createTime: DateTime.now(),
        );
        needToInserts.add(tv);
      }
    }
    if (needToInserts.isNotEmpty) {
      await insertsOrFail(needToInserts);
    }
  }
}
