import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/game_user_score.dart';
import 'package:repeat_flutter/db/entity/game_user_score_history.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/widget/game/game_state.dart';

class GameUserScoreHistoryReq {
  final int? lastId;
  final int pageSize;

  GameUserScoreHistoryReq({
    this.lastId,
    required this.pageSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'lastId': lastId,
      'pageSize': pageSize,
    };
  }

  factory GameUserScoreHistoryReq.fromJson(Map<String, dynamic> json) {
    return GameUserScoreHistoryReq(
      lastId: json['lastId'] as int?,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }
}

class GameUserScoreHistoryRes {
  final List<GameUserScoreHistory> history;
  final int totalCount;
  final int pageSize;

  GameUserScoreHistoryRes({
    required this.history,
    required this.totalCount,
    required this.pageSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'history': history.map((e) => e.toJson()).toList(),
      'totalCount': totalCount,
      'pageSize': pageSize,
    };
  }
}

Future<message.Response?> gameUserScoreHistory(message.Request req, GameUser user) async {
  final dao = Db().db.gameUserScoreHistoryDao;

  final lastGameIndex = GameState.lastGameIndex;
  final reqData = GameUserScoreHistoryReq.fromJson(req.data);
  final int? totalCount = await dao.getCount(
    user.id!,
    GameType.values[lastGameIndex],
  );
  if (totalCount == null) {
    return message.Response(error: GameServerError.noData.name);
  }
  final int? lastId = reqData.lastId;
  final int pageSize = reqData.pageSize;

  late List<GameUserScoreHistory> historyList;

  if (lastId != null) {
    historyList = await dao.getPaginatedListWithLastId(
      user.id!,
      GameType.values[lastGameIndex],
      lastId,
      pageSize,
    );
  } else {
    historyList = await dao.getPaginatedList(
      user.id!,
      GameType.values[lastGameIndex],
      pageSize,
    );
  }

  final res = GameUserScoreHistoryRes(
    history: historyList,
    totalCount: totalCount,
    pageSize: pageSize,
  );

  return message.Response(data: res.toJson());
}
