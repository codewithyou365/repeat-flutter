// dao/content_index_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';

@dao
abstract class ContentIndexDao {
  @Query('SELECT * FROM ContentIndex')
  Future<List<ContentIndex>> findContentIndex();


  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertContentIndex(ContentIndex data);

  @delete
  Future<void> deleteContentIndex(ContentIndex data);
}