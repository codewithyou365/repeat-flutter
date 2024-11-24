// dao/content_index_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

@dao
abstract class ContentIndexDao {
  @Query('SELECT * FROM ContentIndex where crn=:crn order by sort')
  Future<List<ContentIndex>> findContentIndex(String crn);

  @Query('SELECT Id99999.id FROM Id99999'
      ' LEFT JOIN ('
      '  select sort from ContentIndex where ContentIndex.crn=:crn'
      ' ) ContentIndex ON ContentIndex.sort = Id99999.id'
      ' WHERE ContentIndex.sort IS NULL'
      ' limit 1')
  Future<int?> getIdleSortSequenceNumber(String crn);

  @Query('SELECT count(1) FROM ContentIndex where crn=:crn and url=:url')
  Future<int?> count(String crn, String url);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertContentIndex(ContentIndex data);

  @delete
  Future<void> deleteContentIndex(ContentIndex data);

  @transaction
  Future<ContentIndex> add(String url) async {
    var idleSortSequenceNumber = await getIdleSortSequenceNumber(Classroom.curr);
    if (idleSortSequenceNumber == null) {
      Snackbar.show(I18nKey.labelTooMuchData.tr);
      return ContentIndex("", "", 0);
    }
    if (await count(Classroom.curr, url) != 0) {
      Snackbar.show(I18nKey.labelDataDuplication.tr);
      return ContentIndex("", "", 0);
    }
    var contentIndex = ContentIndex(Classroom.curr, url, idleSortSequenceNumber);
    await insertContentIndex(contentIndex);
    return contentIndex;
  }
}
