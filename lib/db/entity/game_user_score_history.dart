// entity/game_user_score_history.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date_time_util.dart';

import 'game_user_score.dart';

@Entity(
  indices: [
    Index(value: ['userId', 'gameType']),
    Index(value: ['remark']),
  ],
)
class GameUserScoreHistory {
  @PrimaryKey(autoGenerate: true)
  int? id;
  int userId;
  GameType gameType;
  int inc;
  int before;
  int after;
  String remark;
  DateTime createDate;

  GameUserScoreHistory({
    required this.userId,
    required this.gameType,
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
      gameType: GameType.values[json['gameType'] as int],
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
    'gameType': gameType.index,
    'inc': inc,
    'before': before,
    'after': after,
    'remark': remark,
    'createTime': DateTimeUtil.format(createDate),
  };
}
