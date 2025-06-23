import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/content_version.dart';
import 'package:repeat_flutter/db/entity/verse_content_version.dart';
import 'package:repeat_flutter/db/entity/verse_key.dart';

@dao
abstract class VerseContentVersionDao {
  @Query('SELECT * '
      ' FROM VerseContentVersion'
      ' WHERE verseKeyId=:verseKeyId'
      ' AND t=:verseVersionType')
  Future<List<VerseContentVersion>> list(int verseKeyId, VerseVersionType verseVersionType);

  @Query('SELECT VerseContentVersion.* '
      ' FROM VerseKey'
      ' JOIN VerseContentVersion ON VerseContentVersion.verseKeyId=VerseKey.id'
      '  AND VerseContentVersion.t=:verseVersionType'
      '  AND VerseContentVersion.version=VerseKey.contentVersion'
      ' WHERE VerseContentVersion.bookId=:bookId')
  Future<List<VerseContentVersion>> currVersionList(int bookId, VerseVersionType verseVersionType);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(VerseContentVersion entity);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertsOrIgnore(List<VerseContentVersion> entities);

  @Query('DELETE FROM VerseContentVersion'
      ' WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('DELETE FROM VerseContentVersion WHERE chapterKeyId=:chapterKeyId')
  Future<void> deleteByChapterKeyId(int chapterKeyId);

  @Query('DELETE FROM VerseContentVersion'
      ' WHERE verseKeyId=:verseKeyId')
  Future<void> deleteByVerseKeyId(int verseKeyId);

  Future<Map<int, VerseContentVersion>> import(List<VerseKey> list, VerseVersionType verseTextVersionType, int bookId) async {
    List<VerseContentVersion> insertValues = [];
    List<VerseContentVersion> contentVersion = await currVersionList(bookId, verseTextVersionType);
    Map<int, VerseContentVersion> idToContentVersion = {for (var v in contentVersion) v.verseKeyId: v};
    for (var v in list) {
      VerseContentVersion? version = idToContentVersion[v.id!];
      String text;
      if (verseTextVersionType == VerseVersionType.note) {
        text = v.note;
      } else {
        text = v.content;
      }
      if (version == null || version.content != text) {
        int currVersionNumber = 1;
        if (version != null) {
          currVersionNumber = version.version + 1;
        }
        var stv = VerseContentVersion(
          classroomId: v.classroomId,
          bookId: v.bookId,
          chapterKeyId: v.chapterKeyId,
          verseKeyId: v.id!,
          t: verseTextVersionType,
          version: currVersionNumber,
          reason: VersionReason.import,
          content: text,
          createTime: DateTime.now(),
        );
        insertValues.add(stv);
      }
    }
    if (insertValues.isNotEmpty) {
      await insertsOrIgnore(insertValues);
    }
    Map<int, VerseContentVersion> ret = {for (var v in contentVersion) v.verseKeyId: v};
    return ret;
  }

  List<VerseContentVersion> toNeedToInsertVerseText(
    List<VerseKey> newVerseKeys,
    VerseVersionType verseTextVersionType,
    Map<int, VerseContentVersion> idToContentVersion,
  ) {
    List<VerseContentVersion> insertValues = [];

    for (var v in newVerseKeys) {
      VerseContentVersion? version = idToContentVersion[v.id!];
      String text = v.content;
      if (verseTextVersionType == VerseVersionType.note) {
        text = v.note;
      }
      if (version == null || version.content != text) {
        int currVersionNumber = 1;
        if (version != null) {
          currVersionNumber = version.version + 1;
        }
        var stv = VerseContentVersion(
          classroomId: v.classroomId,
          bookId: v.bookId,
          chapterKeyId: v.chapterKeyId,
          verseKeyId: v.id!,
          t: verseTextVersionType,
          version: currVersionNumber,
          reason: VersionReason.import,
          content: text,
          createTime: DateTime.now(),
        );
        insertValues.add(stv);
      }
    }
    return insertValues;
  }
}
