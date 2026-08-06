import 'package:get/get.dart';

import 'game_list_logic.dart';

class GameListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GameListLogic());
  }
}
