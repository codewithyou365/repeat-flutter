import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/game_user_score.dart';

class GameUserScoreRes {
  final int gameId;
  final int score;

  GameUserScoreRes({
    required this.gameId,
    required this.score,
  });

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'score': score,
    };
  }

  factory GameUserScoreRes.fromJson(Map<String, dynamic> json) {
    return GameUserScoreRes(
      gameId: json['gameId'] as int,
      score: json['score'] as int,
    );
  }
}

Future<message.Response?> gameUserScore(message.Request req, GameUser user) async {
  final dao = Db().db.gameUserScoreDao;

  List<GameUserScore> scores = await dao.listByUserId(user.getId());
  final res = scores
      .map(
        (s) => GameUserScoreRes(
          gameId: s.gameId,
          score: s.score,
        ),
      )
      .toList();

  return message.Response(data: res);
}
