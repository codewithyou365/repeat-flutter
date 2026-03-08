// dao/game_user_score_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user_score.dart';
import 'package:repeat_flutter/db/entity/game_user_score_history.dart';

@dao
abstract class GameUserScoreDao {
  late AppDatabase db;

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(GameUserScore entity);

  @Query(
    'UPDATE GameUserScore '
    'SET score = score + :score '
    'WHERE id = :id',
  )
  Future<void> addScore(int score, int id);

  @Query(
    'SELECT * FROM GameUserScore '
    'WHERE userId = :userId',
  )
  Future<List<GameUserScore>> listByUserId(int userId);

  @Query(
    'SELECT * FROM GameUserScore '
    'WHERE userId = :userId AND gameId = :gameId '
    'LIMIT 1',
  )
  Future<GameUserScore?> get(int userId, int gameId);

  @Query(
    'SELECT * FROM GameUserScore '
    'WHERE userId in (:userIds) AND gameId = :gameId ',
  )
  Future<List<GameUserScore>> list(List<int> userIds, int gameId);

  @transaction
  Future<void> inc(
    int userId,
    GameType gameType,
    int score,
    String remark,
  ) async {
    if (score == 0) {
      return;
    }
    final now = DateTime.now();
    int gameId = 0;
    final existing = await get(userId, gameId);

    if (existing == null) {
      final newScore = GameUserScore(
        userId: userId,
        gameId: gameId,
        score: score,
        createDate: now,
      );

      await insertOrFail(newScore);

      await db.gameUserScoreHistoryDao.insertOrFail(
        GameUserScoreHistory(
          userId: userId,
          gameId: gameId,
          inc: score,
          before: 0,
          after: score,
          remark: remark,
          createDate: now,
        ),
      );
    } else {
      final before = existing.score;
      final after = before + score;

      await addScore(score, existing.id!);

      await db.gameUserScoreHistoryDao.insertOrFail(
        GameUserScoreHistory(
          userId: userId,
          gameId: gameId,
          inc: score,
          before: before,
          after: after,
          remark: remark,
          createDate: now,
        ),
      );
    }
  }
}
