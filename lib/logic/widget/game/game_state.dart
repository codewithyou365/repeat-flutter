import 'package:get/get.dart';

class GameState {
  static int lastGameIndex = 0;
  bool openPending = false;
  RxBool open = RxBool(false);
  RxString online = RxString("");
  RxInt game = RxInt(0);
  List<String> urls = [];
}
