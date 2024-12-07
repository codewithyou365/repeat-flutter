// dao/doc_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/doc.dart';

@dao
abstract class DocDao {
  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  @Query('SELECT id FROM Doc WHERE path=:path')
  Future<int?> getIdByPath(String path);

  @Query('SELECT path FROM Doc WHERE id = :id')
  Future<String?> getPath(int id);

  @Query('SELECT * FROM Doc WHERE path=:path')
  Future<Doc?> getByPath(String path);

  @Query('SELECT * FROM Doc WHERE id=:id')
  Future<Doc?> getById(int id);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertDoc(Doc data);

  @Query('UPDATE OR ABORT Doc SET msg=:msg WHERE id = :id')
  Future<void> updateDoc(int id, String msg);

  @Query('UPDATE OR ABORT Doc SET count=:count,total=:total WHERE id = :id')
  Future<void> updateProgressById(int id, int count, int total);

  @Query("UPDATE OR ABORT Doc SET msg='',count=total,url=:url,path=:path,hash=:hash WHERE id=:id")
  Future<void> updateFinish(int id, String url, String path, String hash);

  @Query("SELECT * FROM Doc WHERE path LIKE :prefixPath || '%'")
  Future<List<Doc>> getAllDoc(String prefixPath);

  @transaction
  Future<Doc> insertByPath(String path) async {
    await forUpdate();
    var ret = await getByPath(path);
    if (ret != null) {
      return ret;
    }
    var cache = Doc("", path, "");
    insertDoc(cache);
    ret = await getByPath(path);
    return ret!;
  }
}
