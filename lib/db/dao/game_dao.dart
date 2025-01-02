// dao/game_dao.dart

import 'dart:convert';

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/db/entity/game.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/game_user_input.dart';
import 'package:repeat_flutter/logic/game_server/game_logic.dart';

@dao
abstract class GameDao {
  @Query('SELECT * FROM Game where finish=false ORDER BY createTime desc LIMIT 1')
  Future<Game?> getLatestOne();

  @Query('SELECT id FROM Game where finish=false')
  Future<List<int>> getAllEnableGameIds();

  @Query('UPDATE Game set finish=true where id in (:gameIds)')
  Future<void> disableGames(List<int> gameIds);

  @Query('SELECT * FROM Game WHERE id=:gameId')
  Future<Game?> one(int gameId);

  @Query('SELECT * FROM GameUserInput WHERE gameId=:gameId and gameUserId=:gameUserId order by createTime desc limit 1')
  Future<GameUserInput?> lastUserInput(int gameId, int gameUserId);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertGame(Game game);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertGameUserInput(GameUserInput gameUserInput);

  @transaction
  Future<Game> tryInsertGame(Game game) async {
    var ids = await getAllEnableGameIds();
    List<int> needDisableGameIds = ids.where((element) => element != game.id).toList();
    if (needDisableGameIds.isNotEmpty) {
      await disableGames(needDisableGameIds);
    }
    var curr = await one(game.id);
    if (curr != null) {
      return curr;
    }
    await insertGame(game);
    return game;
  }

  @transaction
  Future<List<List<String>>> submit(Game game, int gameUserId, String userInput) async {
    GameUserInput? gameUserInput = await lastUserInput(game.id!, gameUserId);
    List<String> prevOutput = [];
    if (gameUserInput != null) {
      prevOutput = ListUtil.toList(gameUserInput.output);
    }
    final now = DateTime.now();
    List<String> output = [];
    List<String> input = GameLogic.processWord(game.w, userInput, output, prevOutput);
    insertGameUserInput(GameUserInput(
      game.id!,
      gameUserId,
      game.segmentKeyId,
      game.classroomId,
      game.contentSerial,
      game.lessonIndex,
      game.segmentIndex,
      jsonEncode(input),
      jsonEncode(output),
      now.millisecondsSinceEpoch,
      Date.from(now),
    ));
    return [input, output];
  }
}
