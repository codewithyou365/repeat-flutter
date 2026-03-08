import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/game.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';

class GameState {
  int lastGameIndex = 0;
  List<Game> games = [];
  static Game? game;

  bool openPending = false;
  RxBool open = RxBool(false);
  RxString online = RxString("");
  List<String> urls = [];

  RxInt userNumber = RxInt(0);
  List<GameUser> users = [];
  Map<int, int> userIdToScore = {};
  RxInt userIndex = RxInt(-1);
}
