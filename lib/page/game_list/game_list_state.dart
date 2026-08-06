import 'package:get/get.dart';

import 'game_list_item.dart';

class GameListState {
  final RxList<GameItem> items = <GameItem>[].obs;
  final RxBool loading = true.obs;
}
