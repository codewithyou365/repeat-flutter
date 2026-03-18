import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/game.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';

class GameState {
  RxInt lastGameIndex = 0.obs;
  List<Game> games = [];
  static Game? game;
  static bool adminEnable = false;
  static int adminId = 0;

  bool openPending = false;
  RxBool adminEnableRx = RxBool(false);
  RxBool open = RxBool(false);
  RxString online = RxString("");
  List<String> urls = [];

  RxInt userNumber = RxInt(0);
  List<GameUser> users = [];
  Map<int, int> userIdToScore = {};
  RxInt userIndex = RxInt(-1);
}
