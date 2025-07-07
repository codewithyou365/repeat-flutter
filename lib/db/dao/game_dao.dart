// dao/game_dao.dart

import 'dart:convert';

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game.dart';
import 'package:repeat_flutter/db/entity/game_user_input.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/game_server/game_logic.dart';

@dao
abstract class GameDao {
  late AppDatabase db;

  @Query("SELECT CAST(value as INTEGER) FROM CrKv WHERE classroomId=:classroomId and k=:k")
  Future<int?> intKv(int classroomId, CrK k);

  @Query("SELECT value FROM CrKv WHERE classroomId=:classroomId and k=:k")
  Future<String?> stringKv(int classroomId, CrK k);

  @Query('UPDATE CrKv SET value=:value WHERE classroomId=:classroomId and k=:k')
  Future<void> updateKv(int classroomId, CrK k, String value);

  @Query('SELECT * FROM Game where finish=false')
  Future<Game?> getOne();

  @Query('UPDATE Game set time=:time,finish=false where id=:gameId')
  Future<void> refreshGame(int gameId, int time);

  @Query('UPDATE Game set verseContent=:verseContent where id=:gameId')
  Future<void> refreshGameContent(int gameId, String verseContent);

  @Query('UPDATE VerseTodayPrg set time=:time where id=:gameId')
  Future<void> refreshVerseTodayPrg(int gameId, int time);

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

  @Query('DELETE FROM GameUserInput WHERE gameId=:gameId and gameUserId=:gameUserId and time=:time')
  Future<void> clearGameUser(int gameId, int gameUserId, int time);

  @Query('DELETE FROM Game WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query('DELETE FROM Game WHERE bookId=:bookId')
  Future<void> deleteByBookId(int bookId);

  @Query('DELETE FROM Game WHERE chapterId=:chapterId')
  Future<void> deleteByChapterId(int chapterId);

  @Query('DELETE FROM Game WHERE verseId=:verseId')
  Future<void> deleteByVerseId(int verseId);

  @transaction
  Future<Game> tryInsertGame(Game game) async {
    var ids = await getAllEnableGameIds();
    List<int> needDisableGameIds = ids.where((element) => element != game.id).toList();
    if (needDisableGameIds.isNotEmpty) {
      await disableGames(needDisableGameIds);
    }
    await refreshVerseTodayPrg(game.id, game.time);
    var curr = await one(game.id);
    if (curr != null) {
      await refreshGame(game.id, game.time);
      return curr;
    }
    await insertGame(game);
    return game;
  }

  @transaction
  Future<void> clearGame(int gameId, int userId, String verseContent) async {
    var game = await one(gameId);
    if (game == null) {
      return;
    }

    await clearGameUser(game.id, userId, game.time);
    await refreshGameContent(game.id, verseContent);
  }

  @transaction
  Future<List<String>> getTip(
    int gameId,
    int gameUserId,
  ) async {
    Game? game = await getOne();
    if (game == null) {
      return [];
    }
    Map<String, dynamic> verse = jsonDecode(game.verseContent);
    GameUserInput? gameUserInput = await lastUserInput(game.id, gameUserId, game.time);
    if (gameUserInput != null) {
      return ListUtil.toList(gameUserInput.output);
    }
    int matchTypeInt = await intKv(Classroom.curr, CrK.matchTypeInTypingGame) ?? 1;
    MatchType matchType = MatchType.values[matchTypeInt];
    int typingGame = await intKv(Classroom.curr, CrK.ignoringPunctuationInTypingGame) ?? 0;
    if (typingGame == 1) {
      var punctuation = getWord(verse).replaceAll(RegExp(r'[\p{L}\p{N}]+', unicode: true), '').trim();
      if (punctuation.isNotEmpty) {
        return GameLogic.processWord(getWord(verse), punctuation, [], [], matchType, null);
      }
    }
    return GameLogic.processWord(getWord(verse), "", [], [], matchType, null);
  }

  @transaction
  Future<GameUserInput> submit(
    int gameId,
    int matchTypeInt,
    int preGameUserInputId,
    int gameUserId,
    String userInput,
    List<String> obtainInput,
    List<String> obtainOutput,
  ) async {
    final game = await one(gameId);
    if (game == null) {
      return GameUserInput.empty();
    }
    Map<String, dynamic> verse = jsonDecode(game.verseContent);
    MatchType matchType = MatchType.values[matchTypeInt];
    GameUserInput? gameUserInput = await lastUserInput(game.id, gameUserId, game.time);
    if (gameUserInput == null && preGameUserInputId != 0) {
      return GameUserInput.empty();
    }
    if (gameUserInput != null && preGameUserInputId != gameUserInput.id) {
      return GameUserInput.empty();
    }
    List<String> prevOutput = [];
    List<String> input = [];

    if (gameUserInput != null) {
      prevOutput = ListUtil.toList(gameUserInput.output);
    } else {
      int typingGame = await intKv(Classroom.curr, CrK.ignoringPunctuationInTypingGame) ?? 0;
      if (typingGame == 1) {
        var punctuation = getWord(verse).replaceAll(RegExp(r'[\p{L}\p{N}]+', unicode: true), '').trim();
        if (punctuation.isNotEmpty) {
          prevOutput = GameLogic.processWord(getWord(verse), punctuation, [], [], matchType, null);
        }
      }
    }
    final now = DateTime.now();
    String? skipChar = await stringKv(Classroom.curr, CrK.skipCharacterInTypingGame);
    if (skipChar != null && skipChar.isEmpty) {
      skipChar = null;
    }
    input = GameLogic.processWord(getWord(verse), userInput, obtainOutput, prevOutput, matchType, skipChar);
    await insertGameUserInput(GameUserInput(
      gameId: game.id,
      gameUserId: gameUserId,
      time: game.time,
      verseId: game.verseId,
      classroomId: game.classroomId,
      bookId: game.bookId,
      chapterId: game.chapterId,
      input: jsonEncode(input),
      output: jsonEncode(obtainOutput),
      createTime: now.millisecondsSinceEpoch,
      createDate: Date.from(now),
    ));
    obtainInput.addAll(input);
    final ret = await lastUserInput(game.id, gameUserId, game.time);
    if (ret == null) {
      return GameUserInput.empty();
    }
    return ret;
  }

  String getWord(Map<String, dynamic> verse) {
    String? w = verse['w'];
    if (w != null) {
      return w;
    }
    return verse['a']!;
  }
}
