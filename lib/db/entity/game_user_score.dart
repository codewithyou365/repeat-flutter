// entity/game_user_score.dart

import 'package:floor/floor.dart';

enum GameType {
  none,
  type,
  blankItRight,
  wordSlicer,
  input,
}

@Entity(
  indices: [
    Index(value: ['userId', 'gameId'], unique: true),
  ],
)
class GameUserScore {
  @PrimaryKey(autoGenerate: true)
  int? id;
  int userId;
  int gameId;
  int score;
  DateTime createDate;

  GameUserScore({
    required this.userId,
    required this.gameId,
    required this.score,
    required this.createDate,
    this.id,
  });
}
