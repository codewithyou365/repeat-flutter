import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/text_version.dart';

@dao
abstract class TextVersionDao {
  @Query('SELECT * FROM TextVersion WHERE t=:type AND id=:id')
  Future<List<TextVersion>> list(TextVersionType type, int id);

  @Query('SELECT TextVersion.* '
      ' FROM ChapterKey'
      ' JOIN TextVersion ON TextVersion.t=2'
      '  AND TextVersion.id=ChapterKey.id'
      '  AND TextVersion.version=ChapterKey.contentVersion'
      ' WHERE ChapterKey.id in (:ids)')
  Future<List<TextVersion>> getTextForChapter(List<int> ids);

  @Query('SELECT TextVersion.* '
      ' FROM TextVersion'
      ' WHERE TextVersion.t=3'
      '  AND TextVersion.id=:bookSerial'
      '  AND TextVersion.version=:version')
  Future<TextVersion?> getTextForBook(int bookSerial, int version);

  @Query('DELETE FROM TextVersion WHERE t=:type AND id=:id')
  Future<void> delete(TextVersionType type, int id);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(TextVersion entity);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertOrIgnore(TextVersion entity);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertsOrIgnore(List<TextVersion> entities);

  @Query('DELETE FROM TextVersion'
      ' WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  List<TextVersion> convert<T>({
    required int classroomId,
    required int bookSerial,
    required TextVersionType textVersionType,
    required List<T> list,
    required int Function(T) getId,
    required String Function(T) getText,
    required Map<int, TextVersion> currIdToVersion,
  }) {
    List<TextVersion> needToInsert = [];

    for (var v in list) {
      int id = getId(v);
      String text = getText(v);
      TextVersion? version = currIdToVersion[id];
      if (version == null || version.text != text) {
        int currVersionNumber = 1;
        if (version != null) {
          currVersionNumber = version.version + 1;
        }
        var tv = TextVersion(
          t: textVersionType,
          id: id,
          classroomId: classroomId,
          bookSerial: bookSerial,
          version: currVersionNumber,
          reason: TextVersionReason.import,
          text: text,
          createTime: DateTime.now(),
        );
        needToInsert.add(tv);
      }
    }
    return needToInsert;
  }
}
