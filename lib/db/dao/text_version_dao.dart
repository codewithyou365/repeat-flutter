import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/text_version.dart';

@dao
abstract class TextVersionDao {
  @Query('SELECT * FROM TextVersion WHERE t=:type AND id=:id')
  Future<List<TextVersion>> list(TextVersionType type, int id);

  @Query('SELECT TextVersion.* '
      ' FROM LessonKey'
      ' JOIN TextVersion ON TextVersion.t=2'
      '  AND TextVersion.id=LessonKey.id'
      '  AND TextVersion.version=LessonKey.contentVersion'
      ' WHERE LessonKey.id in (:ids)')
  Future<List<TextVersion>> getTextForLesson(List<int> ids);

  @Query('SELECT TextVersion.* '
      ' FROM TextVersion'
      ' WHERE TextVersion.t=3'
      '  AND TextVersion.id=:contentSerial'
      '  AND TextVersion.version=:version')
  Future<TextVersion?> getTextForContent(int contentSerial, int version);

  @Query('DELETE FROM TextVersion WHERE t=:type AND id=:id')
  Future<void> delete(TextVersionType type, int id);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertOrIgnore(TextVersion entity);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertsOrIgnore(List<TextVersion> entities);

  List<TextVersion> toNeedToInsert<T>(
    TextVersionType textVersionType,
    List<T> list,
    int Function(T) getId,
    String Function(T) getText,
    Map<int, TextVersion> currIdToVersion,
  ) {
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
