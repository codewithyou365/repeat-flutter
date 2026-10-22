import 'package:get/get.dart';
import 'package:repeat_flutter/logic/model/game_manifest.dart';

import 'game_list_item.dart';

class GameListState {
  final RxList<GameItem> items = <GameItem>[].obs;

  /// 课堂 'ts' 里的提示服务。
  final RxList<TipServiceItem> tipServices = <TipServiceItem>[].obs;

  /// 课堂 'gs' 里的订阅，给「管理订阅」用。
  final RxList<GameSubscription> subscriptions = <GameSubscription>[].obs;

  final RxBool loading = true.obs;
}
