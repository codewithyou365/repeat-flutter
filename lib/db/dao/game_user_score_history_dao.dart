// dao/game_user_score_history_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/game_user_score.dart';
import 'package:repeat_flutter/db/entity/game_user_score_history.dart';

@dao
abstract class GameUserScoreHistoryDao {
  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(GameUserScoreHistory entity);

  @Query('SELECT * FROM GameUserScoreHistory WHERE userId=:userId and gameType=:gameType ORDER BY commitDate DESC LIMIT :limit')
  Future<List<GameUserScoreHistory>> getPaginatedList(int userId, GameType gameType, int limit);

  @Query('SELECT * FROM GameUserScoreHistory WHERE userId=:userId and gameType=:gameType AND id < :lastId ORDER BY commitDate DESC LIMIT :limit')
  Future<List<GameUserScoreHistory>> getPaginatedListWithLastId(int userId, GameType gameType, int lastId, int limit);

  @Query('SELECT COUNT(*) FROM GameUserScoreHistory WHERE userId=:userId and gameType=:gameType')
  Future<int?> getCount(int userId, GameType gameType);

  @Query('SELECT * FROM GameUserScoreHistory WHERE remark=:remark ORDER BY id DESC LIMIT 1')
  Future<GameUserScoreHistory?> getLast(String remark);
}
