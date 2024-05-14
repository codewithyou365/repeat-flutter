// dao/content_index_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';

@dao
abstract class ContentIndexDao {
  @Query('SELECT * FROM ContentIndex where crn=:crn order by sort')
  Future<List<ContentIndex>> findContentIndex(String crn);

  @Query('SELECT Id99999.id FROM Id99999'
      ' LEFT JOIN ContentIndex ON ContentIndex.sort = Id99999.id'
      ' WHERE where crn=:crn'
      ' ContentIndex.sort IS NULL'
      ' limit 1')
  Future<int?> getIdleSortSequenceNumber(String crn);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertContentIndex(ContentIndex data);

  @delete
  Future<void> deleteContentIndex(ContentIndex data);
}
