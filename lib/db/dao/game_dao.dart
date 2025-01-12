// dao/game_dao.dart

import 'dart:convert';

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/db/entity/game.dart';
import 'package:repeat_flutter/db/entity/game_user_input.dart';
import 'package:repeat_flutter/logic/game_server/game_logic.dart';

@dao
abstract class GameDao {
  @Query('SELECT * FROM Game where finish=false')
  Future<Game?> getOne();

  @Query('UPDATE Game set time=:time,finish=false where id=:gameId')
  Future<void> refreshGame(int gameId, int time);

  @Query('UPDATE SegmentTodayPrg set time=:time where id=:gameId')
  Future<void> refreshSegmentTodayPrg(int gameId, int time);

  @Query('SELECT id FROM Game where finish=false')
  Future<List<int>> getAllEnableGameIds();

  @Query('UPDATE Game set finish=true where id in (:gameIds)')
  Future<void> disableGames(List<int> gameIds);

  @Query('SELECT * FROM Game WHERE id=:gameId')
  Future<Game?> one(int gameId);

  @Query('SELECT * FROM GameUserInput WHERE gameId=:gameId and gameUserId=:gameUserId and time=:time order by id desc limit 1')
  Future<GameUserInput?> lastUserInput(int gameId, int gameUserId, int time);

  @Query('SELECT * FROM GameUserInput WHERE gameId=:gameId and gameUserId=:gameUserId and time=:time')
  Future<List<GameUserInput>> gameUserInput(int gameId, int gameUserId, int time);

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
    await refreshSegmentTodayPrg(game.id, game.time);
    var curr = await one(game.id);
    if (curr != null) {
      await refreshGame(game.id, game.time);
      return curr;
    }
    await insertGame(game);
    return game;
  }

  @transaction
  Future<GameUserInput> submit(Game game, int preGameUserInputId, int gameUserId, String userInput, List<String> obtainInput, List<String> obtainOutput) async {
    GameUserInput? gameUserInput = await lastUserInput(game.id, gameUserId, game.time);
    if (gameUserInput == null && preGameUserInputId != 0) {
      return GameUserInput.empty();
    }
    if (gameUserInput != null && preGameUserInputId != gameUserInput.id) {
      return GameUserInput.empty();
    }
    List<String> prevOutput = [];
    if (gameUserInput != null) {
      prevOutput = ListUtil.toList(gameUserInput.output);
    }
    final now = DateTime.now();
    List<String> input = GameLogic.processWord(game.w, userInput, obtainOutput, prevOutput);
    await insertGameUserInput(GameUserInput(
      game.id,
      gameUserId,
      game.time,
      game.segmentKeyId,
      game.classroomId,
      game.contentSerial,
      game.lessonIndex,
      game.segmentIndex,
      jsonEncode(input),
      jsonEncode(obtainOutput),
      now.millisecondsSinceEpoch,
      Date.from(now),
    ));
    obtainInput.addAll(input);
    final ret = await lastUserInput(game.id, gameUserId, game.time);
    if (ret == null) {
      return GameUserInput.empty();
    }
    return ret;
  }

  @transaction
  Future<List<List<String>>> get(Game game, int gameUserId, String userInput) async {
    GameUserInput? gameUserInput = await lastUserInput(game.id, gameUserId, game.time);
    List<String> prevOutput = [];
    if (gameUserInput != null) {
      prevOutput = ListUtil.toList(gameUserInput.output);
    }
    final now = DateTime.now();
    List<String> output = [];
    List<String> input = GameLogic.processWord(game.w, userInput, output, prevOutput);
    insertGameUserInput(GameUserInput(
      game.id,
      gameUserId,
      game.time,
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
