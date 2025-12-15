import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/game_user_score.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

class GameUserScoreMinusReq {
  final bool customReason;
  final int gameType;
  final String reason;
  final int score;

  GameUserScoreMinusReq({
    required this.customReason,
    required this.gameType,
    required this.reason,
    required this.score,
  });

  Map<String, dynamic> toJson() {
    return {
      'customReason': customReason,
      'gameType': gameType,
      'reason': reason,
      'score': score,
    };
  }

  factory GameUserScoreMinusReq.fromJson(Map<String, dynamic> json) {
    return GameUserScoreMinusReq(
      customReason: json['customReason'] as bool,
      gameType: json['gameType'] as int,
      reason: json['reason'] as String,
      score: json['score'] as int,
    );
  }
}

Future<message.Response?> gameUserScoreMinus(
  message.Request req,
  GameUser user,
) async {
  final dao = Db().db.gameUserScoreDao;

  final reqData = GameUserScoreMinusReq.fromJson(req.data);

  if (reqData.score <= 0) {
    return message.Response(
      error: GameServerError.scoreMustBePositive.name,
    );
  }

  final remark = reqData.customReason ? 'c:${reqData.reason}' : 'i:${reqData.reason}';

  dao.inc(
    user.getId(),
    GameType.values[reqData.gameType],
    -reqData.score,
    remark,
  );

  return message.Response();
}
