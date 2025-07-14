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

  @Query('SELECT VerseContentVersion.* '
      ' FROM VerseKey'
      ' JOIN VerseContentVersion ON VerseContentVersion.verseId=VerseKey.id'
      '  AND VerseContentVersion.version=VerseKey.contentVersion'
      ' WHERE VerseContentVersion.bookId=:bookId')
  Future<List<VerseContentVersion>> currVersionList(int bookId);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(VerseContentVersion entity);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertsOrFail(List<VerseContentVersion> entities);

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
    if (needToInserts.isNotEmpty) {
      await insertsOrFail(needToInserts);
    }
  }

  Future<Map<int, VerseContentVersion>> reimport(List<Verse> list, int bookId) async {
    List<VerseContentVersion> insertValues = [];
    List<VerseContentVersion> contentVersion = await currVersionList(bookId);
    Map<int, VerseContentVersion> idToContentVersion = {for (var v in contentVersion) v.verseId: v};
    for (var v in list) {
      VerseContentVersion? version = idToContentVersion[v.id!];
      String text = v.content;
      if (version == null || version.content != text) {
        int currVersionNumber = 1;
        if (version != null) {
          currVersionNumber = version.version + 1;
        }
        var stv = VerseContentVersion(
          classroomId: v.classroomId,
          bookId: v.bookId,
          chapterId: v.chapterId,
          verseId: v.id!,
          version: currVersionNumber,
          reason: VersionReason.import,
          content: text,
          createTime: DateTime.now(),
        );
        insertValues.add(stv);
      }
    }
    if (insertValues.isNotEmpty) {
      await insertsOrFail(insertValues);
    }
    Map<int, VerseContentVersion> ret = {for (var v in contentVersion) v.verseId: v};
    return ret;
  }
}
