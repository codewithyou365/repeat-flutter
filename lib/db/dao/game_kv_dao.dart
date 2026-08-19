// dao/game_kv_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/game_kv.dart';

@dao
abstract class GameKvDao {
  @Query('SELECT value FROM GameKv WHERE gameId=:gameId AND `k`=:k')
  Future<String?> getValue(int gameId, String k);

  @Query('SELECT * FROM GameKv WHERE gameId=:gameId AND `k` IN (:keys)')
  Future<List<GameKv>> findByKeys(int gameId, List<String> keys);

  @Query("SELECT `k` FROM GameKv WHERE gameId=:gameId AND `k` LIKE :prefix || '%' ORDER BY `k` LIMIT :limit")
  Future<List<String>> findKeysByPrefix(int gameId, String prefix, int limit);

  @Query("SELECT COUNT(1) FROM GameKv WHERE gameId=:gameId AND `k` LIKE :prefix || '%'")
  Future<int?> countByPrefix(int gameId, String prefix);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertsOrReplace(List<GameKv> kv);

  @Query('DELETE FROM GameKv WHERE gameId=:gameId AND `k` IN (:keys)')
  Future<void> deleteByKeys(int gameId, List<String> keys);

  @Query('DELETE FROM GameKv WHERE gameId=:gameId')
  Future<void> deleteByGameId(int gameId);

  /// 删课堂时用：Game 行是按 classroomId 整批删的，挂在这些游戏下的 kv 也要跟着走，
  /// 否则 id 被下一个游戏复用时会读到上一个游戏的数据。
  @Query('DELETE FROM GameKv WHERE gameId IN (SELECT id FROM Game WHERE classroomId=:classroomId)')
  Future<void> deleteByClassroomId(int classroomId);
}
