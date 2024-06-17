// dao/doc_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/doc.dart';

@dao
abstract class DocDao {
  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  @Query('SELECT id FROM Doc WHERE url = :url')
  Future<int?> getId(String url);

  @Query('SELECT path FROM Doc WHERE id = :id')
  Future<String?> getPath(int id);

  @Query('SELECT * FROM Doc WHERE url = :url')
  Future<Doc?> one(String url);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertDoc(Doc data);

  @Query('UPDATE OR ABORT Doc SET msg=:msg WHERE id = :id')
  Future<void> updateDoc(int id, String msg);

  @Query('UPDATE OR ABORT Doc SET count=:count,total=:total WHERE id = :id')
  Future<void> updateProgressById(int id, int count, int total);

  @Query('UPDATE OR ABORT Doc SET count=total,path=:path,hash=:hash WHERE id = :id')
  Future<void> updateFinish(int id, String path, String hash);

  @transaction
  Future<Doc> insert(String url) async {
    await forUpdate();
    var ret = await one(url);
    if (ret != null) {
      return ret;
    }
    var cache = Doc(url, "", "");
    insertDoc(cache);
    ret = await one(url);
    return ret!;
  }
}
