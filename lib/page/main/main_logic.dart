import 'package:get/get.dart';
import 'package:repeat_flutter/nav.dart';

import 'main_state.dart';

class MainLogic extends GetxController {
  final MainState state = MainState();

  void onBottomNavigationBarTap(int index) {
    if (index == 2) {
      Nav.mainSettings.push();
    }
    if (index == state.bottomNavigationBarIndex.value) return;
    state.bottomNavigationBarIndex.value = index;
  }
}
