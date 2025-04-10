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
  Future<List<TextVersion>> getTextForLessonContent(List<int> ids);

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
          textVersionType,
          id,
          currVersionNumber,
          TextVersionReason.import,
          text,
          DateTime.now(),
        );
        needToInsert.add(tv);
      }
    }
    return needToInsert;
  }
}
