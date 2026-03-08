// entity/game_user_score_history.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date_time_util.dart';

@Entity(
  indices: [
    Index(value: ['userId', 'gameId']),
    Index(value: ['remark']),
  ],
)
class GameUserScoreHistory {
  @PrimaryKey(autoGenerate: true)
  int? id;
  int userId;
  int gameId;
  int inc;
  int before;
  int after;
  String remark;
  DateTime createDate;

  GameUserScoreHistory({
    required this.userId,
    required this.gameId,
    required this.inc,
    required this.before,
    required this.after,
    required this.remark,
    required this.createDate,
    this.id,
  });

  factory GameUserScoreHistory.fromJson(Map<String, dynamic> json) {
    return GameUserScoreHistory(
      userId: json['userId'] as int,
      gameId: json['gameId'] as int,
      inc: json['inc'] as int,
      before: json['before'] as int,
      after: json['after'] as int,
      remark: json['remark'] as String,
      createDate: DateTimeUtil.parse(json['createDate'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id!,
    'userId': userId,
    'gameId': gameId,
    'inc': inc,
    'before': before,
    'after': after,
    'remark': remark,
    'createTime': DateTimeUtil.format(createDate),
  };
}
